# How AI Works in Lanttern Today

> Technical reference document — April 2026
>
> Audience: developers, architects, and technical decision-makers working on Lanttern's AI roadmap.

---

## 1. Executive Summary

Lanttern currently has **two independent AI-powered features**, built at different times and using different libraries:

| Feature | Purpose | Library | LLM Provider | Async? |
|---------|---------|---------|-------------|--------|
| **Agent Chat** | Conversational lesson planning assistant | LangChain 0.4.0 | OpenAI (ChatOpenAI) | Yes (Oban) |
| **ILP AI Revision** | Automated review of Individual Learning Plans | ReqLLM ~> 1.6 | OpenAI (via ReqLLM) | No (synchronous) |

Both features communicate exclusively with **OpenAI's API** and share a single API key. There is no streaming — all responses are generated in full before being delivered to the user.

A third dependency, **LLMDB (~> 2026.3.1)**, serves as a model validation catalog (used to verify that a configured model name is valid).

---

## 2. Dependency Map

```
mix.exs
├── {:langchain, "0.4.0"}          # Agent Chat — chains, function calling, message types
├── {:req_llm, "~> 1.6"}           # ILP Revision — simple text generation
└── {:llm_db, "~> 2026.3.1"}       # Model name validation (LLMDB.allowed?/1)
```

### Why two LLM libraries?

The ILP Revision feature was originally built (March 2025 — migrations `20250319*`) using `req_llm`, a lightweight Req-based LLM wrapper. The Agent Chat was built later (January 2026 — migrations `20260106*`) using LangChain, which provides chain orchestration and function calling.

As noted in the project's planning document (`ai-agent-features-lanttern.md`), the team is considering **consolidating on `req_llm`** (part of the Jido ecosystem) and phasing out LangChain. The rationale: LangChain adds abstraction overhead that may not be needed, and `req_llm` is lighter and closer to the Elixir idiom.

### Environment Variables

| Variable | Used by | Required |
|----------|---------|----------|
| `OPENAI_API_KEY` | LangChain, ReqLLM | Yes (production) |
| `OPENAI_ORG_ID` | LangChain | Optional |

Configuration lives in `config/config.exs` (compile-time) and `config/runtime.exs` (production runtime):

```elixir
# config/config.exs:98-100 (compile-time, all environments)
config :langchain, openai_key: System.get_env("OPENAI_API_KEY")
config :langchain, openai_org_id: System.get_env("OPENAI_ORG_ID")

# config/runtime.exs:98-99 (runtime, all environments — inside prod check is repeated)
config :langchain, openai_key: System.get_env("OPENAI_API_KEY")
config :langchain, openai_org_id: System.get_env("OPENAI_ORG_ID")

# config/runtime.exs:196-197 (runtime, production ONLY — inside `if config_env() == :prod` block)
config :req_llm, openai_api_key: System.get_env("OPENAI_API_KEY")
```

Note: `req_llm` is only configured in the production block of `runtime.exs`. In dev/test, it relies on the test stub (`Lanttern.ReqLLMStub`) injected via the `req_llm_module` parameter.

---

## 3. Feature 1: Agent Chat (Conversational Lesson Planning)

### 3.1 Overview

A multi-turn chat interface where teachers interact with an AI assistant to plan lessons. The AI is context-aware — it knows about the school's curriculum, the strand (unit of study), the specific lesson, and the teacher's preferences. It can also **execute actions** (create/update lessons) via LLM function calling.

### 3.2 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  Parent LiveView (StrandChatLive / LessonChatLive)                  │
│    • Subscribes to PubSub topic "conversation:{id}"                 │
│    • Forwards PubSub events to ConversationComponent via            │
│      send_update/3                                                  │
│                                                                     │
│  └── ConversationComponent (UI: messages, prompt, selectors)        │
│        • Handles user prompt submission                             │
│        • Calls AgentChat context for data operations                │
│        • Enqueues Oban job after data is persisted                  │
└────────────────────────┬────────────────────────────────────────────┘
                         │ 1. User submits message
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Step A: Data persistence (AgentChat context)                       │
│                                                                     │
│  create_conversation_with_message/3  or  add_user_message/3         │
│    → Insert user message into DB (Ecto.Multi)                       │
│    → Set conversation.status = "processing"                         │
│                                                                     │
│  Step B: Job enqueue (ConversationComponent)                        │
│                                                                     │
│  enqueue_chat_response_job/2                                        │
│    → ChatResponseWorker.new(args) |> Oban.insert()                  │
└────────────────────────┬────────────────────────────────────────────┘
                         │ 2. Oban picks up the job
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ChatResponseWorker (lib/lanttern/workers/chat_response_worker.ex)  │
│  Oban queue: :ai, max_attempts: 3, unique: true                     │
│                                                                     │
│  1. Resolve model (job arg → school config → app default)           │
│  2. Create ChatOpenAI instance (stream: false)                      │
│  3. Fetch conversation + all messages from DB                       │
│  4. Call AgentChat.run_llm_chain/4                                  │
│     → Build system messages (5-layer hierarchy)                     │
│     → Attach tools (create_lesson, update_lesson)                   │
│     → Run LangChain (mode: :while_needs_response)                  │
│     → Tool timeout: 5 minutes (async_tool_timeout)                  │
│  5. Extract response content + aggregate token usage                │
│  6. Save assistant message + ModelCall to DB                        │
│  7. Mark conversation idle                                          │
│  8. Broadcast via PubSub → parent LiveView → send_update to        │
│     ConversationComponent                                           │
│  9. Auto-rename conversation if unnamed                             │
└─────────────────────────────────────────────────────────────────────┘
```

Note: the Oban job is enqueued by the `ConversationComponent` (the LiveComponent), not by the `AgentChat` context module. The context is responsible only for data persistence (messages, status). This keeps the context module free of side effects beyond the database.

### 3.3 System Prompt Construction (5-Layer Hierarchy)

The system messages are prepended to the LangChain call in a **fixed order** to benefit from OpenAI's prompt caching. This ordering is intentional — see `agent_chat.ex:461-478`.

```
Layer 1: School Knowledge & Guardrails
  └── Source: SchoolConfig.AiConfig (school_ai_configs table)
  └── Tags: <school_knowledge>...</school_knowledge>
            <school_guardrails>...</school_guardrails>

Layer 2: Agent Configuration
  └── Source: Agents.Agent (ai_agents table)
  └── Tags: <agent_personality>...</agent_personality>
            <agent_instructions>...</agent_instructions>
            <agent_knowledge>...</agent_knowledge>
            <agent_guardrails>...</agent_guardrails>

Layer 3: Staff Member Context
  └── Source: Schools.StaffMember (staff table)
  └── Tag: <staff_member_context>
              <name>...</name>
              <role>...</role>
              <about>...</about>
              <preferences>...</preferences>
            </staff_member_context>

Layer 4: Lesson Template
  └── Source: LessonTemplates (lesson_templates table)
  └── Tags: <lesson_template_info>...</lesson_template_info>
            <lesson_template>...</lesson_template>

Layer 5: Curriculum Context
  └── Strand: <strand_context> with name, subjects, years, curriculum items,
              overview, teacher_instructions, moments
  └── Lesson: <lesson_context> with name, moment, subjects, tags,
              overview, teacher_notes, differentiation_notes
  └── Tool Args: <tools_args> with moments/subjects/tags IDs
                 (only if function calling is enabled)
```

Each layer is conditionally included — if the data doesn't exist (e.g., no agent selected, no lesson context), the corresponding system messages are simply not added.

### 3.4 Function Calling (Tool Use)

Two LangChain `Function` tools are available, depending on the context:

**`create_lesson`** — Available in strand-level chat (`strand_id` required)
- Parameters: `moment_id`, `subjects_ids`, `tags_ids`, `description`, `teacher_notes`, `differentiation_notes`
- Calls `Lessons.create_lesson(scope, args, is_ai_agent: true)`
- The `<tools_args>` system message provides the valid moment/subject/tag IDs

**`update_lesson`** — Available in lesson-level chat (`lesson_id` required)
- Same parameters as create
- Calls `Lessons.update_lesson(scope, lesson, args, is_ai_agent: true)`

**Audit Log integration:**
When the AI creates or updates a lesson, the operation is recorded in `LessonLog` with `is_ai_agent: true` (via `AuditLog.maybe_log/5`). This allows distinguishing AI-generated lessons from human-created ones for observability and analytics.

**Auto-rename via function calling:**
When a conversation has no name, the worker triggers `rename_conversation_based_on_chain/3`, which uses a separate LLM call with a `set_conversation_title` function to generate a concise title from the first 4 messages. This is a non-critical operation — failures are silently ignored.

The chain runs with `mode: :while_needs_response`, meaning LangChain will automatically handle multi-turn tool calling (LLM requests tool call → tool executes → result fed back → LLM responds). Tool execution has a 5-minute timeout (`async_tool_timeout: 5 * 60 * 1000`).

### 3.5 Model Resolution

The model is resolved with a 3-level fallback chain (`chat_response_worker.ex:120-131`):

```
1. Job argument (explicit override per request)      → args["model"]
2. School configuration (admin-configured default)   → AiConfig.base_model
3. Application default (hardcoded)                   → "gpt-5-nano"
```

### 3.6 Token Tracking

Every assistant message generates a `ModelCall` record with:
- `prompt_tokens` — total input tokens across all LLM calls in the exchange
- `completion_tokens` — total output tokens
- `model` — the model used

Token usage is aggregated from `chain.exchanged_messages` because a single user prompt may trigger multiple LLM calls (tool calls, retries). See `chat_response_worker.ex:133-156`.

**Notable gap:** There is no token-per-user limit, no budget enforcement, and no cost alerting. Token data is stored but not acted upon.

### 3.7 Real-Time Updates

The system uses Phoenix PubSub for real-time communication between the Oban worker and the LiveView:

```
Topic: "conversation:#{conversation_id}"

Events:
  {:conversation, {:message_added, %Message{}}}
  {:conversation, {:failed, error}}
  {:conversation, {:conversation_renamed, %Conversation{}}}
```

The **parent LiveView** (StrandChatLive/LessonChatLive) subscribes to the PubSub topic when a conversation is loaded (`AgentChat.subscribe_conversation/1` in `apply_action(:show)`). When events arrive, the parent forwards them to the `ConversationComponent` via `send_update/3`. The component itself does not subscribe to PubSub — it only reacts to updates from its parent. When the user navigates to a different conversation, the parent calls `unsubscribe_all()` before subscribing to the new topic.

The conversation's `status` field ("idle" | "processing") prevents race conditions — the UI shows a loading state while processing.

### 3.8 Database Schema

```
ai_agents
├── id, name, knowledge, personality, guardrails, instructions
├── school_id → schools
└── timestamps

school_ai_configs
├── id, base_model, knowledge, guardrails
├── school_id → schools (unique)
└── timestamps

agent_conversations
├── id, name, status ("idle"|"processing"), last_error
├── profile_id → profiles
├── school_id → schools
└── timestamps

agent_messages
├── id, role ("user"|"assistant"|"system"), content
├── conversation_id → agent_conversations
└── timestamps

llm_calls
├── id, prompt_tokens, completion_tokens, model
├── message_id → agent_messages (unique)
└── timestamps

strand_agent_conversations
├── id
├── conversation_id → agent_conversations
├── strand_id → strands
├── lesson_id → lessons (nullable)
└── timestamps

staff (existing table, AI-related field)
└── agent_conversation_preferences (text)
```

### 3.9 Routes

```
/strands/:strand_id/chat              → StrandChatLive :new
/strands/:strand_id/chat/:conv_id     → StrandChatLive :show
/strands/lesson/:lesson_id/chat       → LessonChatLive :new
/strands/lesson/:lesson_id/chat/:id   → LessonChatLive :show
/settings/agents                      → AgentsSettingsLive :index
/settings/agents/:id                  → AgentsSettingsLive :show
/settings/school_ai_config            → SchoolAiConfigLive :index
```

### 3.10 Permissions

All Agent Chat features require the `"agents_management"` permission. The check is done in two different ways across the codebase:

- **Chat pages and context modules** use `Scope.has_permission?(scope, "agents_management")` (the recommended pattern per CLAUDE.md)
- **Settings pages** (`SchoolAiConfigLive`, `AgentsSettingsLive`) check `current_user.current_profile.permissions` directly — this is an older pattern that predates the `Scope` convention (technical debt)

---

## 4. Feature 2: ILP AI Revision

### 4.1 Overview

A simpler, synchronous AI feature that reviews a student's Individual Learning Plan (ILP) and generates a revision/feedback document. Unlike the Agent Chat, this is a **single-shot generation** — no conversation, no function calling, no async processing.

### 4.2 Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Two entry points (both call ILP.revise_student_ilp/5):          │
│                                                                  │
│  1. ActionBarComponent — "Generate revision" button              │
│     Shown when NO revision exists yet                            │
│                                                                  │
│  2. OverlayComponent — "Update revision" button                  │
│     Shown inside the overlay that displays the current revision  │
│                                                                  │
│  Preconditions (both components check before showing the form):  │
│  • All ILP entries must be filled (every entry.description ≠ nil)│
│  • Template must have ai_layer.revision_instructions set         │
│  • Template must have ai_layer.model set                         │
└────────────────────────┬─────────────────────────────────────────┘
                         │ User enters student age, submits
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  ILP.revise_student_ilp/5  (lib/lanttern/ilp.ex:743)            │
│                                                                  │
│  1. Convert StudentILP to text via student_ilp_to_text/3         │
│     → Iterates template sections/components + ILP entries        │
│     → Produces markdown: "# Section\n## Component\ncontent"     │
│                                                                  │
│  2. Build ReqLLM.Context                                         │
│     → System: template.ai_layer.revision_instructions            │
│     → User: "review the ILP for a student with age {age}\n"     │
│             + formatted ILP text                                 │
│                                                                  │
│  3. ReqLLM.generate_text(model, context)  ← synchronous call    │
│     Model comes from template.ai_layer.model (NOT school config) │
│                                                                  │
│  4. Save result to StudentILP via ai_changeset/2:                │
│     → ai_revision (the generated text)                           │
│     → last_ai_revision_input (the prompt sent)                   │
│     → ai_revision_datetime (UTC timestamp)                       │
│                                                                  │
│  5. Create audit log via ILPLog.maybe_create_student_ilp_log/3   │
│     (uses log_profile_id option to link to requesting user)      │
└──────────────────────────────────────────────────────────────────┘
```

### 4.3 Configuration

Each ILP template can have an associated `ILPTemplateAILayer` (1:1 relationship via `template_id` as primary key):

| Field | Type | Purpose |
|-------|------|---------|
| `revision_instructions` | text | System prompt for the AI revision |
| `model` | string | LLM model (validated via `LLMDB.allowed?/1`) |
| `cooldown_minutes` | integer (default 0) | Minimum minutes between revision requests |

### 4.4 Cooldown Mechanism

The `StudentILPAIRevisionOverlayComponent` checks the time elapsed since `ai_revision_datetime` against `cooldown_minutes` (using `Timex.diff/3`). If the cooldown hasn't expired, the "Update revision" form is hidden and a countdown is shown instead. The `ActionBarComponent` does not implement cooldown — it only appears when no revision exists yet, so cooldown is not applicable.

This is a **UI-side enforcement** — there is no server-side cooldown validation in `revise_student_ilp/5`. A direct call to the context function would bypass the cooldown.

### 4.5 Testing Strategy

The function accepts `req_llm_module` as a dependency-injected parameter (defaults to `ReqLLM`). In tests, `Lanttern.ReqLLMStub` is passed instead, which returns a hardcoded stub response:

```elixir
# test/support/stubs/req_llm.ex
def generate_text(_model, _context, _opts \\ []) do
  {:ok, %ReqLLM.Response{
    message: %ReqLLM.Message{
      content: [ReqLLM.Message.ContentPart.text("This is a stub response.")]
    }
  }}
end
```

### 4.6 Database Fields

On `students_ilps` table (existing table, AI fields added via migration `20250319193523`):

```
ai_revision          :string    # The generated revision text
last_ai_revision_input :string  # The prompt that was sent (audit trail)
ai_revision_datetime :utc_datetime  # When the revision was generated
```

The same fields are mirrored in `student_ilp_logs` for the audit trail.

A dedicated `ai_changeset/2` is used to separate AI-generated content from human-edited content (`student_ilp.ex:95`).

---

## 5. Shared Infrastructure

### 5.1 Oban Job Queue

```elixir
# config/config.exs:103-114
config :lanttern, Oban,
  queues: [cleanup: 1, ai: 10],
  plugins: [Oban.Plugins.Pruner, {Oban.Plugins.Cron, crontab: [...]}]
```

- The `ai` queue has **10 concurrent workers**, meaning up to 10 AI chat responses can be processed simultaneously.
- `ChatResponseWorker` uses `unique: true` to prevent duplicate jobs for the same conversation.
- In test environment: `config :lanttern, Oban, testing: :manual` (jobs don't execute automatically).
- `Oban.Plugins.Pruner` cleans up completed jobs automatically.

### 5.2 Audit Log — `is_ai_agent` Flag

The `AuditLog` module (`lib/lanttern/audit_log.ex`) accepts an `:is_ai_agent` option on `maybe_log/5`. When the AI agent creates or updates a lesson via tool calling, `Lessons.create_lesson/3` and `Lessons.update_lesson/4` pass `is_ai_agent: true`, which is persisted in the `LessonLog` schema. This enables querying "which lessons were created by AI vs. humans."

Currently, only `LessonLog` uses this flag. The ILP revision has its own separate audit trail (via `ILPLog`) that does not use `is_ai_agent` — instead, it simply records the operation linked to the requesting user's `profile_id`.

### 5.3 Application Default Model

```elixir
# chat_response_worker.ex:129
Application.get_env(:lanttern, :default_llm_model, "gpt-5-nano")
```

This is the ultimate fallback when neither the job nor the school configuration specify a model.

### 5.4 UI Component Library

All AI features share a consistent visual language via dedicated components:

| Component | Location | Purpose |
|-----------|----------|---------|
| `ai_panel_overlay/1` | `ai_components.ex` | Full-screen modal with AI amber theme |
| `floating_ai_button/1` | `ai_components.ex` | Fixed FAB to open AI panels |
| `ai_action_bar/1` | `ai_components.ex` | Horizontal bar with AI branding |
| `ai_content_indicator/1` | `ai_components.ex` | Dot indicator for AI-generated content |
| `ai_box/1` | `core_components.ex` | Container with AI border styling |
| `ai_generated_content_disclaimer/1` | `core_components.ex` | "AI makes mistakes" warning |

The visual theme uses custom Tailwind classes (`ltrn-ai-*`) with amber tones, animated "spectrum spots" (blur-based gradient circles), and the `hero-sparkles-mini` icon.

---

## 6. Complete Migration Timeline

| Date | Migration | What it did |
|------|-----------|-------------|
| 2025-03-19 | `create_ilp_template_ai_layers` | ILP AI layer table (revision_instructions) |
| 2025-03-19 | `add_ai_fields_to_students_ilps` | ai_revision, last_ai_revision_input, ai_revision_datetime |
| 2025-04-03 | `add_model_and_cooldown_to_ilp_template_ai_layers` | model, cooldown_minutes fields |
| 2026-01-06 | `create_ai_agents` | ai_agents table |
| 2026-01-13 | `create_agent_conversations` | agent_conversations table |
| 2026-01-13 | `create_agent_messages` | agent_messages table |
| 2026-01-13 | `create_llm_calls` | llm_calls table (token tracking) |
| 2026-01-14 | `add_unique_message_id_constraint_to_llm_calls` | 1:1 message-to-model_call |
| 2026-01-14 | `add_school_id_to_agent_conversations` | school_id on conversations |
| 2026-01-21 | `create_strand_agent_conversations` | strand/lesson conversation links |
| 2026-02-03 | `create_school_ai_configs` | school_ai_configs table |
| 2026-03-06 | `add_agent_conversation_preferences_to_staff` | staff preferences field |
| 2026-03-06 | `add_status_to_agent_conversations` | status + last_error fields |

The ILP feature (2025) predates the Agent Chat (2026) by ~9 months.

---

## 7. Configuration Hierarchy

```
Environment Variables
  OPENAI_API_KEY ─────────────────────────────────────┐
  OPENAI_ORG_ID ──────────────────────────────────┐   │
                                                  │   │
Application Config                                │   │
  config :langchain, openai_key: ────────────────►│◄──┤
  config :langchain, openai_org_id: ─────────────►│   │
  config :req_llm, openai_api_key: ──────────────►────┤
  config :lanttern, :default_llm_model ──────► "gpt-5-nano" (hardcoded fallback)
                                                  │
School-Level Config (per school, DB)              │
  school_ai_configs.base_model ──────────────────►│ (overrides app default)
  school_ai_configs.knowledge ───────────────► system prompt layer 1
  school_ai_configs.guardrails ──────────────► system prompt layer 1
                                                  │
Agent-Level Config (per school, DB)               │
  ai_agents.personality ─────────────────────► system prompt layer 2
  ai_agents.instructions ────────────────────► system prompt layer 2
  ai_agents.knowledge ──────────────────────► system prompt layer 2
  ai_agents.guardrails ─────────────────────► system prompt layer 2
                                                  │
ILP Template Config (per template, DB)            │
  ilp_template_ai_layers.revision_instructions ──► system prompt (ILP only)
  ilp_template_ai_layers.model ─────────────────► model override (ILP only)
  ilp_template_ai_layers.cooldown_minutes ──────► rate limit (ILP only)
                                                  │
Per-Request Override                              │
  ChatResponseWorker job args: model ───────────►│ (highest priority for chat)
```

---

## 8. Architectural Observations

### What's working well

1. **Clean separation of concerns.** The Oban worker pattern decouples the LiveView from LLM latency. The UI stays responsive, and PubSub provides clean real-time updates.

2. **Hierarchical system prompt construction.** The 5-layer prompt hierarchy is well-organized and explicitly ordered for prompt caching. Each layer is self-contained and conditionally included.

3. **Token tracking.** Every LLM call is recorded with token counts, enabling future cost analysis and budgeting.

4. **School-scoped multi-tenancy.** AI configuration (model, knowledge, guardrails, agents) is fully scoped to schools. Different schools can have completely different AI setups.

5. **Audit trail for ILP revisions.** The combination of `last_ai_revision_input` + `ai_revision_datetime` + ILPLog snapshots provides full traceability.

### Known gaps and trade-offs

1. **No streaming.** The LLM is called with `stream: false` (`chat_response_worker.ex:57`). The user sees a loading indicator until the full response is generated. For long responses, this can feel slow.

2. **No token/cost limits.** Token data is stored but there's no per-user, per-school, or per-conversation budget enforcement. A single user could theoretically exhaust the API budget.

3. **Dual library situation.** LangChain (Agent Chat) and ReqLLM (ILP Revision) serve overlapping purposes. This increases the cognitive load for developers and the surface area for dependency management.

4. **Synchronous ILP revision.** Unlike the Agent Chat, ILP revisions block the LiveView process during the API call. If the OpenAI API is slow or down, the user's browser tab hangs.

5. **Client-side only cooldown.** The ILP cooldown is enforced in the UI but not in the context function. A crafted request could bypass it.

6. **No conversation memory across sessions.** Each conversation is independent. The agent has no awareness of previous conversations with the same user, previous lesson plans, or the broader history. This is explicitly called out as a future requirement in `ai-agent-features-lanttern.md`.

7. **Text-only tool call results.** When the AI creates a lesson, the chat shows a text confirmation. There are no rich UI components rendered inline in the conversation (also identified as a future goal).

8. **Single provider dependency.** Both libraries are configured exclusively for OpenAI. There's no abstraction layer for switching providers, though ReqLLM and LangChain both support multiple providers in theory.

---

## 9. File Reference Index

### Core AI Modules
| File | Purpose |
|------|---------|
| `lib/lanttern/agent_chat.ex` | Agent Chat context — orchestration, LLM chain, system prompts |
| `lib/lanttern/agents.ex` | Agent CRUD context |
| `lib/lanttern/agents/agent.ex` | Agent Ecto schema |
| `lib/lanttern/agent_chat/conversation.ex` | Conversation schema |
| `lib/lanttern/agent_chat/message.ex` | Message schema |
| `lib/lanttern/agent_chat/model_call.ex` | Token tracking schema |
| `lib/lanttern/agent_chat/strand_conversation.ex` | Strand/lesson link schema |
| `lib/lanttern/workers/chat_response_worker.ex` | Oban worker for async LLM calls |
| `lib/lanttern/school_config.ex` | School config context (includes AI config CRUD) |
| `lib/lanttern/school_config/ai_config.ex` | School AI config schema |
| `lib/lanttern/ilp.ex` | ILP context (includes `revise_student_ilp/5`) |
| `lib/lanttern/ilp/ilp_template_ai_layer.ex` | ILP template AI layer schema |
| `lib/lanttern/ilp/student_ilp.ex` | Student ILP schema (AI fields + ai_changeset) |
| `lib/lanttern/audit_log.ex` | Shared audit log with `is_ai_agent` flag support |
| `lib/lanttern/lessons/lesson_log.ex` | Lesson audit log (includes `is_ai_agent` field) |

### UI Layer
| File | Purpose |
|------|---------|
| `lib/lanttern_web/components/ai_components.ex` | AI panel overlay, floating button, action bar |
| `lib/lanttern_web/components/core_components.ex` | ai_box, ai_generated_content_disclaimer |
| `lib/lanttern_web/live/shared/agent_chat/conversation_component.ex` | Chat conversation UI |
| `lib/lanttern_web/live/shared/agent_chat/agent_preferences_overlay_component.ex` | User AI preferences |
| `lib/lanttern_web/live/shared/agent_chat/rename_conversation_form_component.ex` | Conversation rename |
| `lib/lanttern_web/live/pages/strands/id/chat/strand_chat_live.ex` | Strand-level chat page |
| `lib/lanttern_web/live/pages/strands/lesson/id/chat/lesson_chat_live.ex` | Lesson-level chat page |
| `lib/lanttern_web/live/pages/settings/agents/agents_settings_live.ex` | Agent management settings |
| `lib/lanttern_web/live/pages/settings/school_ai_config/school_ai_config_live.ex` | School AI config settings |
| `lib/lanttern_web/live/shared/ilp/student_ilp_ai_revision_overlay_component.ex` | ILP revision overlay |
| `lib/lanttern_web/live/shared/ilp/student_ilp_ai_revision_action_bar_component.ex` | ILP revision action bar |

### Config & Test
| File | Purpose |
|------|---------|
| `config/config.exs` | LangChain config, Oban queue setup |
| `config/runtime.exs` | Runtime LangChain + ReqLLM API key config |
| `config/test.exs` | Oban testing: :manual |
| `test/support/stubs/req_llm.ex` | ReqLLM test stub |
| `mix.exs` | Dependencies: langchain, req_llm, llm_db |
