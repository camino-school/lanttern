# Lanttern AI Agent Architecture Plan

> Technical architecture document — April 2026
>
> Audience: developers, architects, and technical decision-makers working on Lanttern's AI roadmap.
>
> This document is **opinionated** — it presents all options with pros/cons but makes clear recommendations with justifications for each architectural decision.

---

## Table of Contents

1. [Context & Problem Statement](#1-context--problem-statement)
2. [Architectural Decisions](#2-architectural-decisions)
   - [Decision 1: LLM Client Layer](#decision-1-llm-client-layer)
   - [Decision 2: Agent Orchestration](#decision-2-agent-orchestration)
   - [Decision 3: Chat UI & Frontend](#decision-3-chat-ui--frontend)
   - [Decision 4: Streaming](#decision-4-streaming)
   - [Decision 5: User Memory](#decision-5-user-memory)
   - [Decision 6: Universal Conversation Context](#decision-6-universal-conversation-context)
   - [Decision 7: Observability](#decision-7-observability)
   - [Decision 8: Monolith vs Microservice](#decision-8-monolith-vs-microservice)
3. [Deep Dive: Vercel AI SDK](#3-deep-dive-vercel-ai-sdk)
4. [Deep Dive: Langfuse](#4-deep-dive-langfuse)
5. [Deep Dive: Microservice Architecture & Cross-Language Ecosystems](#5-deep-dive-microservice-architecture--cross-language-ecosystems)
6. [Deep Dive: Choosing a Frontend Stack — CopilotKit + AG-UI vs Vercel AI SDK vs assistant-ui](#6-deep-dive-choosing-a-frontend-stack--copilotkit--ag-ui-vs-vercel-ai-sdk-vs-assistant-ui)
7. [Target Architecture](#7-target-architecture)
8. [Database Schema Evolution](#8-database-schema-evolution)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Risk Assessment](#10-risk-assessment)

---

## 1. Context & Problem Statement

### What we have today

Lanttern currently has **two independent AI features** built at different times using different libraries:

| Feature | Library | Purpose | Async? |
|---------|---------|---------|--------|
| Agent Chat | LangChain 0.4.0 | Conversational lesson planning | Yes (Oban) |
| ILP AI Revision | ReqLLM ~> 1.6 | Automated ILP review | No (synchronous) |

Both features communicate exclusively with **OpenAI's API**. There is no streaming — all responses are generated in full before delivery.

### Why we need to refactor now

The current implementation was designed as a **proof of concept (POC)**. With agentic AI being Lanttern's core 2026 feature, continuing to iterate on the POC foundation will produce a snowball of technical debt. The specific issues:

1. **Dual library overhead**: Maintaining two LLM libraries (LangChain + ReqLLM) doubles cognitive load, dependency surface, and config complexity.
2. **No streaming**: Users wait for full response generation — unacceptable UX for longer interactions.
3. **No cross-conversation memory**: Every conversation starts from zero. The agent has no awareness of previous interactions with the same user.
4. **Hardcoded context**: The conversation UI is tied to strands/lessons. The vision is a universal, context-aware chat.
5. **Text-only tool results**: When the AI creates a lesson, it writes "The lesson was created" in plain text. No rich UI components.
6. **No cost controls**: Token data is stored but not acted upon. No budgets, no limits, no alerts.
7. **No observability**: Beyond token counts, there's no tracing, evaluation, or prompt management infrastructure.
8. **Single provider lock-in**: Both libraries are configured exclusively for OpenAI with no abstraction layer.

### Scope of this document

This document defines the **target architecture** and a **phased implementation roadmap** to address all of the above. Not everything will be built in a single sprint — the plan spreads across 5 phases, each ~2 weeks.

---

## 2. Architectural Decisions

### Decision 1: LLM Client Layer

**Question**: Which library should Lanttern use to interact with LLM APIs?

#### Options

| Dimension | Option A: Status quo (LangChain + ReqLLM) | Option B: Consolidate on ReqLLM | Option C: Full Jido stack |
|---|---|---|---|
| **Migration cost** | Zero | Moderate (2 files, ~25 API call sites) | High (new framework, new paradigms) |
| **Multi-provider** | Both support it in theory; code hardcodes `ChatOpenAI` | 10+ providers native (OpenAI, Anthropic, Google, Mistral, Groq, AWS Bedrock...) | Same as ReqLLM (jido_ai wraps req_llm) |
| **Streaming** | LangChain supports it, not currently used | `stream_text/3` native SSE support | Same as ReqLLM |
| **Tool calling** | LangChain `Function`/`FunctionParam` — verbose | `ReqLLM.Tool` — simpler API | `jido_action` — typed actions with compile-time validation, auto-convert to LLM tools |
| **Cognitive load** | Two APIs, two abstractions, two configs | One API, one abstraction, one config | One ecosystem, but large surface area (jido + jido_ai + jido_action + jido_signal) |
| **Testing** | LangChain uses Mimic; ReqLLM uses dependency injection | Unified stub pattern (already have `ReqLLMStub`) | New test patterns needed |
| **Elixir idiom** | LangChain is a port, not native Elixir design | Native Elixir, built on Req | Native Elixir |
| **Maturity** | LangChain 0.4.0 (unclear update cadence) | v1.0+ stable, production-ready | Jido v2.0 (new, smaller community) |
| **Orchestration included?** | Yes (LLMChain with `while_needs_response`) | No — you build the tool-call loop | Yes (ReAct, Chain-of-Thought, CoD strategies) |

#### Recommendation: **Option B — Consolidate on ReqLLM**

**Justification:**

1. The LangChain coupling surface is small and bounded — exactly 2 files (`agent_chat.ex` and `chat_response_worker.ex`) with ~25 API call sites. The migration is predictable.
2. ReqLLM is already in the project, already tested, and its stub pattern (`Lanttern.ReqLLMStub`) is established.
3. ReqLLM is a focused library (LLM client, not framework) — it does one thing well and leaves orchestration to the application. This matches Lanttern's philosophy of owning business logic.
4. The `while_needs_response` tool-calling loop that LangChain provides is **20-30 lines of custom Elixir code** — not a reason to keep an entire framework dependency.
5. Jido (Option C) adds too much framework surface for the current team size. It introduces new concepts (directives, signals, agent state machines) that are not needed for the current use cases. It can be reconsidered when agent complexity warrants it (multiple independent agents, agent-to-agent communication, complex state machines).
6. Consolidating to one library halves the dependency surface, simplifies testing, and removes the LangChain config from `config.exs` and `runtime.exs`.

**What we lose from LangChain and how to replace it:**

| LangChain feature | Replacement in ReqLLM |
|---|---|
| `LLMChain` with `while_needs_response` | Custom `tool_call_loop/3` function (~25 lines) |
| `ChatOpenAI.new!` | `ReqLLM.generate_text/3` with provider config |
| `Function` / `FunctionParam` | `ReqLLM.Tool` definitions |
| `Message.new_user!` / `new_assistant!` / `new_system!` | `ReqLLM.Context.user/1` / `ReqLLM.Context.assistant/1` / `ReqLLM.Context.system/1` |
| `ContentPart.content_to_string/1` | `ReqLLM.Response.text/1` |
| Token metadata from `chain.exchanged_messages` | `ReqLLM.Response` usage fields |

#### Cross-language perspective: What would this look like in Python or TypeScript?

| Dimension | Elixir (ReqLLM) | Python | TypeScript |
|---|---|---|---|
| **LLM Client** | ReqLLM (community, 10+ providers) | OpenAI SDK / Anthropic SDK (first-class, official, feature-complete) | OpenAI SDK / Anthropic SDK (equal to Python) |
| **Tool calling** | `ReqLLM.Tool` — manual definitions | `Instructor` (3M+ downloads, schema-first) or `Pydantic AI` (typed, auto-validated) | Vercel AI SDK `tool()` or `zod` schema validation |
| **Structured output** | Ecto schema validation (manual) | `Instructor` or `Pydantic AI` — automatic structured LLM outputs with retries | `zod` + Vercel AI SDK `generateObject()` |
| **Maturity** | ReqLLM v1.0 (stable, small community) | OpenAI SDK v1.x (massive community, official support, millions of users) | OpenAI SDK (equal features, Zod-powered types) |
| **Multi-provider** | Native (10+ via ReqLLM) | Native (each provider has official SDK) + LiteLLM as unified wrapper | Native + Vercel AI SDK abstracts providers |

**Verdict**: Python and TypeScript have **significantly better LLM client tooling** — official SDKs, automatic structured output validation, and larger communities. ReqLLM is adequate but requires more custom code. This gap is real but manageable within `AgentChat.LLM` — the abstraction isolates it.

---

### Decision 2: Agent Orchestration

**Question**: How should Lanttern orchestrate AI agent execution (job management, retries, lifecycle)?

#### Options

| Dimension | Option A: Oban-based (current, enhanced) | Option B: GenServer agents (Jido-style) | Option C: Hybrid (Oban + Task.Supervisor) |
|---|---|---|---|
| **Works today** | Yes, proven in production | No — new architecture | Partially |
| **Streaming support** | Requires parallel path (Task) | Natural fit (GenServer sends incremental messages) | Task.Supervisor handles streaming path |
| **Reliability** | Built-in retries, dead-letter, unique constraints | Must build crash recovery, supervision | Oban for reliability; Tasks for streaming |
| **Observability** | Oban Web dashboard already exists | Must build custom | Oban Web for jobs; telemetry for tasks |
| **Failure handling** | Automatic retry with backoff | GenServer restart via supervisor | Split: Oban retries for batch; task failures for streaming |
| **Testability** | `testing: :manual` — jobs don't auto-execute | GenServer testing patterns | Two test patterns to maintain |
| **Memory integration** | Worker queries memory before building prompts | Agent holds conversation state in memory | Same as Option A |
| **Complexity** | Low — workers are just modules | High — supervision tree, state management, deployment | Moderate — two execution paths |

#### Recommendation: **Option A — Continue Oban-based, with streaming extension (Option C) when streaming is added**

**Justification:**

1. **Oban works.** It provides retries, unique constraints, pruning, observability (via Oban Web), and test isolation (`testing: :manual`). Replacing it would be replacing something that isn't broken.
2. Adding streaming later does not require replacing Oban — it means adding a parallel path using `Task.Supervisor` for the streaming case. The worker can choose to stream or batch based on configuration.
3. GenServer agents (Option B) add operational complexity that a small team should avoid unless there is a clear need for in-memory agent state. Currently, all state is in the database — there's no need for in-memory state machines.
4. If Jido agents are needed in the future (e.g., multi-agent coordination), they can coexist with Oban. This is not an either-or decision.

#### Cross-language perspective: What would this look like in Python or TypeScript?

| Dimension | Elixir (Oban) | Python | TypeScript |
|---|---|---|---|
| **Agent framework** | Custom tool_call_loop (~25 lines) | **LangGraph** — stateful agents with checkpointing, time-travel debugging, human-in-the-loop, 5 streaming modes. Industry standard. | **LangGraph.js** — same features, smaller community (42k weekly npm downloads vs Python's dominance) |
| **Multi-agent** | Nothing production-ready | **CrewAI** (role-based agent teams), **AG2/AutoGen** (complex multi-agent), **Swarm** (lightweight) | LangGraph.js multi-agent, Mastra (emerging) |
| **Background jobs** | Oban (proven, retries, dashboard, Postgres-backed) | **Celery + Redis** (mature, durable) or **LangGraph** durable execution | **BullMQ** (911-8,300 jobs/sec, Redis-backed) |
| **State management** | Database (PostgreSQL) | LangGraph checkpointing (in-memory or persistent) — pause/resume/time-travel | LangGraph.js checkpointing |
| **Fault tolerance** | Oban retries + BEAM supervisors | Celery retries + LangGraph checkpoint recovery | BullMQ retries |

**Verdict**: The orchestration gap is the **largest gap** between Elixir and Python. LangGraph provides stateful agent execution, checkpointing, human-in-the-loop, and multi-agent coordination — none of which exist in Elixir. For Lanttern's current needs (simple request-response agents), Oban is sufficient. But if agents become stateful (tutoring sessions, multi-step workflows), LangGraph's advantages become compelling. This is the primary reason to consider a Python sidecar in the future.

---

### Decision 3: Chat UI & Frontend

**Question**: What technology should power the AI chat user interface?

#### Options

| Dimension | Option A: Enhanced LiveView | Option B: React island + Vercel AI SDK | Option C: React island + assistant-ui | Option D: CopilotKit |
|---|---|---|---|---|
| **Migration cost** | Zero | High (React setup + SSE endpoint + hook bridge) | High (React setup + custom protocol) | Very high (full platform adoption) |
| **Streaming UX** | LiveView streams + PubSub token-by-token push | `useChat` hook handles natively | Custom streaming hook | Built-in streaming |
| **Rich components** | Function components in message stream (lesson cards, etc.) | React components for tool call results — full flexibility | Same as Vercel | Same but more opinionated |
| **Team familiarity** | High — entire team knows LiveView | Low — React setup in progress, team learning | Low | Low |
| **Auto-scroll, reconnect, abort** | Must build manually | `useChat` provides all of these | Partially provided | Fully provided |
| **Build complexity** | None | esbuild JSX compilation or Vite for React subtree | Same as Vercel | Same + platform SDK |
| **Dependency footprint** | None | `ai` npm package (~40KB) + React | `@assistant-ui/react` + React | `@copilotkit/react-*` + backend SDK |
| **Backend coupling** | LiveView socket | SSE endpoint (Vercel Data Stream Protocol) — separate from LiveView | Custom protocol | CopilotKit protocol |
| **Model agnostic** | Yes (backend chooses model) | Yes (backend streams, SDK is model-agnostic) | Yes | Yes |
| **Community adoption** | Phoenix community | Industry standard for AI chat | Growing, newer | Large, enterprise-focused |

#### Recommendation: **Option A (Enhanced LiveView) now; transition to Option B (Vercel AI SDK) when React setup is ready**

**Justification:**

1. **Immediate pragmatism**: The React integration is in progress but not ready. Blocking AI architecture work on a React setup would delay the deliverable. LiveView can deliver everything needed for v0: message display, loading states, and even streaming via PubSub.

2. **LiveView handles rich components natively**: When the AI creates a lesson, the `ConversationComponent` can render a `<.lesson_card>` function component inline in the message stream. This requires zero React. The message schema extension (Phase 2) enables this: store `ui_component: "lesson_card"` and `ui_data: %{lesson_id: 123}` in message metadata, then pattern-match in the template.

3. **The Vercel AI SDK is the right long-term choice**: Once React islands are available, the `useChat` hook provides streaming management, auto-scroll, optimistic updates, abort handling, and tool call rendering — all things that would be significant effort to build in LiveView. The transition path is clean because the backend contract (`AgentChat` context, Oban workers, PubSub) is UI-agnostic.

4. **Avoid CopilotKit**: It's a full platform with its own backend framework, which conflicts with Lanttern's Elixir-centric architecture. assistant-ui is a viable alternative to Vercel AI SDK but has a smaller community and less integration documentation for non-Next.js backends.

**Transition plan**:
- Phase 1-3: Use LiveView for chat UI. Build all backend infrastructure (LLM abstraction, context, memory) without coupling to any frontend framework.
- Phase 4-5: When React islands are ready, create a chat React island using Vercel AI SDK. Add an SSE endpoint in Phoenix that speaks the Vercel Data Stream Protocol. Both LiveView and React paths can coexist during transition.

#### Cross-language perspective

The Chat UI decision is mostly **language-agnostic on the backend** — the frontend is React regardless. However, with a TypeScript backend, the Vercel AI SDK would be **native** (no SSE bridge needed — the backend produces the stream directly). With a Python backend (FastAPI), SSE streaming is also native (`StreamingResponse`). With Elixir, we need a custom Phoenix controller to produce the Vercel protocol — doable but more manual work.

**Verdict**: TypeScript has a slight edge for chat UI integration (native Vercel AI SDK). Python and Elixir are equivalent (both need an SSE endpoint). This doesn't justify a language change since the UI layer is a thin translation.

---

### Decision 4: Streaming

**Question**: How should Lanttern deliver AI responses to the user in real-time?

#### Options

| Dimension | Option A: No streaming (current) | Option B: LiveView PubSub streaming | Option C: SSE endpoint (Vercel Data Stream Protocol) |
|---|---|---|---|
| **UX** | User waits for full response (can be 10-30 seconds) | Tokens appear as they're generated | Same as B |
| **Implementation** | Nothing to do | Worker/Task calls ReqLLM with streaming; broadcasts chunks via PubSub; ConversationComponent appends chunks | Phoenix controller returns `text/event-stream`; Vercel AI SDK `useChat` consumes |
| **Backend changes** | None | `AgentChat.LLM` needs streaming path; PubSub events for chunks | New controller + SSE response handler |
| **Frontend changes** | None | ConversationComponent needs chunk buffer + animation | React island with `useChat` hook |
| **Tool calls during stream** | N/A | Worker pauses stream, executes tool, resumes | Vercel SDK handles via `9:` event type |
| **Works with LiveView** | Yes | Yes | No (requires React) |
| **Works with React** | Yes (but poor UX) | No (React doesn't receive PubSub) | Yes (designed for this) |

#### Recommendation: **Option B for Phase 2 (LiveView streaming); add Option C in Phase 5 when React is ready**

**Justification:**

1. **Streaming is a UX improvement, not a blocking architecture issue.** Phase 1 should focus on library consolidation and abstraction. Streaming can follow once the foundation is solid.

2. **Option B keeps everything within the LiveView paradigm** — no separate API endpoint, no additional auth/CSRF handling, no React dependency. It uses the existing PubSub infrastructure that already connects the Oban worker to the LiveView.

3. **The streaming protocol is additive**: When React is ready (Phase 5), Option C (SSE endpoint) is added alongside Option B, not replacing it. The backend can support both paths simultaneously — the Oban worker produces chunks, which are delivered via PubSub (for LiveView) or SSE (for React).

**PubSub streaming design:**

```
New PubSub events:
  {:conversation, {:chunk, %{text: "partial text", index: 0}}}
  {:conversation, {:tool_call_start, %{name: "create_lesson", args: %{...}}}}
  {:conversation, {:tool_call_result, %{name: "create_lesson", result: %{...}}}}
  {:conversation, {:message_complete, %Message{}}}

ConversationComponent:
  - Maintains `streaming_buffer` assign (accumulates chunks)
  - On `:chunk` → append to buffer, re-render streaming message
  - On `:message_complete` → finalize buffer into stream entry, save to DB
```

#### Cross-language perspective

| Dimension | Elixir (PubSub) | Python (FastAPI) | TypeScript (Node.js) |
|---|---|---|---|
| **Streaming to client** | PubSub → LiveView push (custom) | `StreamingResponse` (native SSE) | Vercel AI SDK `streamText()` (native, zero config) |
| **LangGraph streaming** | N/A | **5 streaming modes**: tokens, events, updates, messages, custom. The most advanced streaming in any framework. | LangGraph.js — same 5 modes |
| **Tool calls in stream** | Manual pause/resume logic | LangGraph handles automatically with `astream_events` | LangGraph.js or Vercel AI SDK `9:` event type |
| **Reconnection** | Custom (must build) | Custom (must build) | Vercel AI SDK `useChat` handles automatically |

**Verdict**: Python (LangGraph) has the **best streaming capabilities** — 5 distinct modes that cover every use case (token streaming, state updates, tool call events, custom data). TypeScript (Vercel AI SDK) has the best frontend streaming integration. Elixir's PubSub approach works but requires more custom code for advanced scenarios. For simple token streaming, all three are adequate.

---

### Decision 5: User Memory

**Question**: How should the agent remember information across conversations?

#### Design approach: **Hierarchical summary-based memory**

**Why not raw history replay?** Storing and replaying raw conversation history as "memory" is cost-prohibitive. A user with 50 conversations of 20 messages each would require injecting ~1000 messages into every new prompt — blowing the context window and token budget.

**Why summaries?** At conversation close (or at checkpoints), a background job summarizes the conversation into compact memory entries. These summaries are injected as a Layer 0 system message (before school config) in future conversations — adding ~200-500 tokens of context instead of thousands.

#### Schema design

```
user_ai_memories
  id              :bigint PK
  profile_id      :bigint FK -> profiles (indexed)
  school_id       :bigint FK -> schools (indexed)
  category        :string  -- "preference" | "topic_expertise" | "interaction_style" | "context"
  summary         :text    -- compressed memory text
  source_type     :string  -- "conversation" | "system" | "manual"
  source_id       :bigint  -- nullable, FK to conversation that produced this memory
  relevance_score :float   -- for ranking during retrieval (0.0-1.0)
  expires_at      :utc_datetime -- nullable, for time-bounded memories
  inserted_at     :utc_datetime
  updated_at      :utc_datetime
```

#### Memory lifecycle

1. **Creation**: After a conversation ends (or at periodic checkpoints), a `MemorySummaryWorker` Oban job summarizes the conversation and upserts memory entries.
2. **Injection**: Before building system prompts, `add_memory_system_messages/2` queries the user's recent/relevant memories and injects them as Layer 0 (before school knowledge/guardrails). Memories are sorted by `relevance_score` and capped (e.g., top 10 entries) to control prompt size.
3. **Decay**: Memories have optional `expires_at` for time-bounded information. A cron job prunes expired entries.
4. **Update**: The summarization job can update existing memories (e.g., "user prefers detailed lesson plans" gets refined over time) rather than always creating new ones.
5. **Manual management**: Staff can view and delete their own memories via a settings page.

#### System prompt with memory (6-layer hierarchy)

```
Layer 0: User Memory (NEW)
  └── Source: user_ai_memories table
  └── Tag: <user_memory>
            <preferences>...</preferences>
            <topic_expertise>...</topic_expertise>
            <interaction_history>...</interaction_history>
          </user_memory>

Layer 1: School Knowledge & Guardrails (unchanged)
Layer 2: Agent Configuration (unchanged)
Layer 3: Staff Member Context (unchanged)
Layer 4: Lesson Template (unchanged)
Layer 5: Curriculum Context (unchanged)
```

Memory is placed before school config because it changes most frequently (per-user, per-conversation), while school config is relatively static. This ordering maximizes prompt caching effectiveness — the static layers remain in the same position across calls.

#### Cross-language perspective

| Dimension | Elixir (custom) | Python | TypeScript |
|---|---|---|---|
| **Memory system** | Custom `user_ai_memories` table + summarization job | **mem0** (managed memory layer, auto-categorizes, vector search), **MemGPT/Letta** (self-editing memory, tiered storage), **LangGraph checkpointing** (conversation state persistence with time-travel) | LangGraph.js checkpointing, custom implementations |
| **Vector search for memories** | pgvector (works, manual integration) | **LlamaIndex** memory modules, pgvector, Pinecone, Qdrant — all with first-class integrations | pgvector, Pinecone — similar to Python |
| **Summarization** | Custom Oban job + LLM call | mem0 handles automatically, or LangGraph's `summarize_messages` built-in | Custom or LangGraph.js |

**Verdict**: Python has **specialized memory systems** (mem0, MemGPT/Letta) that don't exist in Elixir. However, these are most valuable for complex agents with long interaction histories. Our custom summary-based memory is simpler and more tailored to Lanttern's school-scoped needs. If memory requirements grow significantly (e.g., vector-based semantic retrieval over thousands of conversations), Python's ecosystem becomes more attractive.

---

### Decision 6: Universal Conversation Context

**Question**: How should conversations be linked to arbitrary entities (strands, lessons, ILPs, assessments, etc.)?

#### Current limitation

The `strand_agent_conversations` table is hardcoded to strands and lessons:

```sql
strand_agent_conversations
  conversation_id → agent_conversations
  strand_id → strands
  lesson_id → lessons (nullable)
```

This cannot accommodate new context types (ILPs, assessments, students, etc.) without new join tables for each entity type.

#### Recommendation: **Polymorphic context link table**

```sql
conversation_contexts
  id                :bigint PK
  conversation_id   :bigint FK -> agent_conversations (CASCADE DELETE)
  context_type      :string  -- "strand" | "lesson" | "ilp" | "assessment" | ...
  context_id        :bigint  -- FK to the relevant entity
  context_metadata  :jsonb   -- snapshot of context data at conversation time
  inserted_at       :utc_datetime

  UNIQUE(conversation_id, context_type, context_id)
```

#### Key design decisions

1. **Multiple contexts per conversation**: A conversation about a lesson within a strand has two context links: `{type: "strand", id: 1}` and `{type: "lesson", id: 5}`. This is more flexible than forcing a single context.

2. **context_metadata JSONB**: Stores a snapshot of relevant context data at conversation creation time. This is useful for audit (what did the agent see?) and for cases where the source entity changes after the conversation.

3. **No FK constraint on context_id**: Because `context_id` can reference different tables depending on `context_type`, we cannot use a database foreign key. Referential integrity is enforced at the application level via `ContextResolver`.

4. **Migration path**: Data from `strand_agent_conversations` is migrated into `conversation_contexts` (one row per strand, one per lesson where applicable). The old table is left as-is per CLAUDE.md rule 7 (default is tech debt, not refactoring).

#### Context resolution pipeline

```elixir
# In AgentChat.ContextResolver
def resolve_contexts(conversation_id) do
  conversation_id
  |> list_conversation_contexts()
  |> Enum.flat_map(&context_to_system_messages/1)
end

defp context_to_system_messages(%{context_type: "strand", context_id: id}) do
  # Load strand with subjects, years, moments, curriculum items
  # Build <strand_context> XML system messages
end

defp context_to_system_messages(%{context_type: "lesson", context_id: id}) do
  # Load lesson with moment, subjects, tags
  # Build <lesson_context> XML system messages
end

defp context_to_system_messages(%{context_type: "ilp", context_id: id}) do
  # Load ILP with template, sections, entries
  # Build <ilp_context> XML system messages
end
```

Adding a new context type requires only adding a new `context_to_system_messages/1` clause — no schema changes, no migrations.

#### Cross-language perspective

Context resolution is **deeply coupled to Lanttern's domain** — loading strands, lessons, ILPs requires querying Ecto schemas with preloaded associations, enforcing Scope authorization, and respecting school isolation. This is the decision **most affected by the monolith vs microservice choice**.

| Scenario | Elixir monolith | Python/TS microservice |
|---|---|---|
| **Loading context** | Direct Ecto query with preloads — 1 DB call, ~5ms | Microservice calls Phoenix internal API → Phoenix queries DB → serializes → returns JSON. Multiple hops, ~50-100ms. |
| **New context type** | Add one function clause in ContextResolver | Add API endpoint in Phoenix + client code in Python/TS + serialization mapping |
| **Authorization** | Pattern-match `school_id` in function head (native Scope) | Must pass Scope token to microservice or duplicate auth logic |
| **Data freshness** | Always live from DB | Risk of stale data if caching, or extra latency if always fetching |

**Verdict**: Context resolution is the **strongest argument for keeping AI in the Elixir monolith**. Moving it to a microservice doesn't simplify it — it adds a network boundary across the tightest coupling point. A Python/TS microservice would either need to access Lanttern's database directly (tight coupling, defeats the purpose) or call internal APIs for every context lookup (latency, complexity).

---

### Decision 7: Observability

**Question**: How should Lanttern monitor, evaluate, and manage AI agent quality and costs?

#### Options

| Dimension | Option A: Custom (DB + Telemetry) | Option B: Langfuse (self-hosted) | Option C: Langfuse Cloud | Option D: LangSmith | Option E: Helicone |
|---|---|---|---|---|---|
| **Data ownership** | Full | Full (your infrastructure) | Langfuse-managed (EU/US regions, GDPR compliant) | LangChain-managed | Helicone-managed |
| **Cost** | DB storage only | Free software + infra ($500-5k/mo) | Free to $199+/mo | $39/seat/mo | Usage-based |
| **Setup effort** | Must build everything | Docker Compose (dev) or K8s/Helm (prod) | SaaS signup | SaaS signup | Proxy setup |
| **Tracing** | Manual (log to DB) | Distributed tracing, span hierarchy, sessions | Same | Same | Proxy-based auto-trace |
| **Prompt management** | None (prompts in code) | Versioning, caching, playground | Same | Yes | No |
| **Evaluation** | None | LLM-as-judge, manual labeling, datasets | Same | Yes | No |
| **Cost tracking** | Aggregate from `llm_calls` | Per-model, per-user, per-session | Same | Yes | Yes (primary feature) |
| **Elixir integration** | Native telemetry | OpenTelemetry or REST API | Same | Python/JS SDKs only | HTTP proxy (language-agnostic) |
| **Vendor lock-in** | None | Low (open source, can migrate data) | Medium (migration to self-host) | High (proprietary, LangChain-focused) | Medium |

#### Recommendation: **Phased approach — Custom (Phase 1-2) → Langfuse Cloud (Phase 3) → Langfuse self-hosted (Phase 5+)**

**Justification:**

1. **Phase 1-2 (Custom)**: The existing `llm_calls` table already captures what is needed for basic cost tracking. Add `:telemetry` events for LLM calls (`:lanttern, :llm, :call, :start/:stop`) and a periodic Oban cron job to aggregate costs per school. This is low-effort and integrates with the existing LiveDashboard.

2. **Phase 3 (Langfuse Cloud)**: Once the memory system is in place and conversations become more complex, adopt Langfuse Cloud for proper tracing and evaluation. The Cloud tier starts free (50k traces/month) and scales to $29/month (1M traces). Integration via OpenTelemetry — which has strong Elixir/BEAM support — or direct REST API.

3. **Phase 5+ (Langfuse self-hosted)**: When trace volume justifies it or data sensitivity requires it, migrate to self-hosted Langfuse on Kubernetes. The transition is straightforward because the integration layer (OpenTelemetry) doesn't change.

**Why not LangSmith?** It's proprietary, LangChain-focused (we're removing LangChain), and has per-seat pricing. **Why not Helicone?** It's proxy-based, which doesn't fit our Oban worker architecture (the LLM call happens server-side, not via a proxy). **Why Langfuse?** Open source, self-hostable, framework-agnostic, no per-seat pricing, and its v4 architecture (ClickHouse-backed) handles scale well.

See [Section 4: Deep Dive: Langfuse](#4-deep-dive-langfuse) for complete technical analysis.

#### Cross-language perspective

| Dimension | Elixir | Python | TypeScript |
|---|---|---|---|
| **Langfuse integration** | OpenTelemetry or REST API (no official SDK) | **Official SDK** — native decorators, auto-tracing, prompt management | **Official SDK** — same features as Python |
| **LangSmith** | No SDK (REST only) | **Native integration** — auto-traces LangChain/LangGraph calls, playground, datasets | LangChain.js auto-tracing |
| **Evaluation frameworks** | None | **DeepEval** (pytest-like LLM testing), **RAGAS** (RAG evaluation), **PromptFoo** (red-teaming/safety) | PromptFoo (works with TS), limited others |
| **Prompt management** | Code-only (system prompts in `agent_chat.ex`) | Langfuse/LangSmith prompt versioning, **DSPy** (automatic prompt optimization) | Langfuse prompt versioning |

**Verdict**: Python has a **significantly better observability and evaluation ecosystem**. DeepEval, RAGAS, and PromptFoo have no Elixir equivalents — and evaluation is critical for education (safety, quality assurance). This is a genuine gap. The phased Langfuse approach mitigates the observability gap, but evaluation frameworks remain a Python-only advantage. If rigorous AI quality evaluation becomes a requirement, this is the second strongest argument (after orchestration) for a Python sidecar.

---

### Decision 8: Monolith vs Microservice — Should AI Live Outside Elixir?

**Question**: Would we get significantly better tooling by building AI features as a separate service in Python or TypeScript?

#### The honest answer: Yes, the tooling is better. The question is whether it's worth the cost.

Python's AI ecosystem is **objectively richer** than Elixir's. The cross-language comparisons in Decisions 1-7 above show real gaps in orchestration (LangGraph), evaluation (DeepEval/RAGAS), memory (mem0), and provider SDKs (official vs community). These aren't theoretical — they represent production-ready tools with large communities.

But tooling quality is only one variable. The full equation includes operational cost, domain coupling, team expertise, and architectural complexity.

#### Options

| Dimension | Option A: Elixir monolith | Option B: Python sidecar (co-deployed) | Option C: Full microservice (separate deploy) |
|---|---|---|---|
| **AI ecosystem access** | Elixir only (ReqLLM, custom code) | **Full Python ecosystem** (LangGraph, DeepEval, official SDKs) | Full Python or TS ecosystem |
| **Deployment** | Single unit | Single unit (same pod/VM) | Separate units |
| **Latency overhead** | 0ms (in-process) | +5-10ms (localhost HTTP) | +25-50ms (network hop) |
| **Tool execution** | Direct function call (`Lessons.create_lesson/3`) | Internal HTTP to Phoenix → business logic | External API → Phoenix → business logic |
| **Context loading** | Direct Ecto query (~5ms) | HTTP to Phoenix → Ecto query → serialize (~50-100ms) | Same as sidecar but across network |
| **PubSub streaming** | Native | Redis bridge or webhook → Phoenix PubSub | Same as sidecar |
| **Infra cost multiplier** | 1x | 1.1-1.3x | 3.75-6x |
| **Team requirement** | Elixir devs | Elixir + 1-2 Python devs | Elixir + 2-4 Python devs + platform engineer |
| **Auth/Scope** | Native pattern matching | Must pass scope or duplicate auth | Same + network auth layer |
| **DB access** | Shared (Ecto) | Shared PostgreSQL (direct or via API) | Separate DB or shared (both have issues) |
| **Testability** | Single test suite | Two test suites, integration tests needed | Same + contract testing |
| **When to choose** | AI is simple, team is small, domain coupling is tight | Need specific Python capabilities, have Python expertise | AI must scale independently, team >50 |

#### The core trade-off: Ecosystem vs Domain Integration

Lanttern's AI agent is not a standalone chatbot — it reaches deep into the application domain:

1. **System prompts** load from 6+ tables (school configs, agents, staff, templates, strands, lessons)
2. **Tool execution** calls business functions with Scope authorization and audit logging
3. **Real-time updates** flow through Phoenix PubSub
4. **Memory injection** queries school-scoped user memories
5. **Context resolution** loads polymorphic entities with Ecto associations

A microservice boundary would cut across these coupling points. The microservice either:
- **Accesses Lanttern's DB directly** (tight coupling, shared schema, migration coordination) — defeats the purpose of separation
- **Calls Phoenix APIs for everything** (latency, staleness risk, API surface to maintain) — adds complexity

#### Recommendation: **Option A (Elixir monolith) now, with a clear path to Option B (Python sidecar) when specific needs arise**

**Justification:**

1. **Current needs are served.** Lanttern needs an LLM client, tool calling, streaming, and memory. ReqLLM + custom code delivers this. LangGraph's advanced features (checkpointing, multi-agent) are not yet needed.

2. **Domain coupling is the decisive factor.** The tightest coupling is context loading and tool execution — both require direct access to Ecto schemas and Scope authorization. A microservice adds friction at the worst possible point.

3. **Industry data supports this.** 42% of organizations that adopted microservices have consolidated back (CNCF 2025 survey). Amazon Prime Video achieved 90% cost reduction migrating from microservices to monolith.

4. **The sidecar escape hatch exists.** `AgentChat.LLM` is designed so the LLM orchestration call can be redirected to an external service. When Python capabilities are needed, we extract ONLY the LLM orchestration to a co-deployed FastAPI sidecar — without moving domain logic, auth, or data access.

#### When to adopt a Python sidecar (Option B)

| Trigger | Why | What to extract |
|---|---|---|
| Multi-agent coordination needed | LangGraph/CrewAI have no Elixir equivalent | Agent orchestration only |
| RAG over large document corpora | LlamaIndex is far ahead | Document processing + retrieval |
| Rigorous evaluation required | DeepEval/RAGAS/PromptFoo are Python-only | Evaluation pipeline |
| Python AI engineer hired | Can own the sidecar without burdening Elixir team | Whatever they're best at |
| Team grows beyond 30 engineers | Independent AI team velocity justified | Full AI orchestration |

See [Section 5: Deep Dive: Microservice Architecture](#5-deep-dive-microservice-architecture--cross-language-ecosystems) for detailed ecosystem comparisons, architecture diagrams, and cost analysis.

---

## 3. Deep Dive: Vercel AI SDK

### What it is

The Vercel AI SDK (`ai` npm package) is a TypeScript toolkit for building AI-powered applications. Despite the name, it is **framework-agnostic** — it works with React, Vue, Svelte, and any backend that produces the correct streaming protocol.

### Architecture

```
┌─────────────────────────────────────────────────┐
│  React Application                               │
│                                                   │
│  useChat() hook                                   │
│    ├── Manages message state (user + assistant)   │
│    ├── Handles streaming (auto-appends tokens)    │
│    ├── Abort / retry / reload                     │
│    ├── Auto-scroll management                     │
│    ├── Tool call rendering                        │
│    └── Configurable API endpoint                  │
│                                                   │
│  Custom tool call renderers                       │
│    └── e.g., <LessonCard> for create_lesson       │
└───────────────────────┬─────────────────────────┘
                        │ POST /api/chat
                        │ Content-Type: text/event-stream
                        │ x-vercel-ai-ui-message-stream: v1
                        ▼
┌─────────────────────────────────────────────────┐
│  Backend (Phoenix SSE endpoint)                   │
│                                                   │
│  Produces Server-Sent Events per protocol:        │
│    0:{text}              → text token             │
│    9:{tool_call_json}    → tool call started      │
│    a:{tool_result_json}  → tool call result       │
│    e:{finish_json}       → stream finished        │
│    d:{usage_json}        → token usage metadata   │
│                                                   │
│  The backend controls model, prompts, tools —     │
│  the SDK only consumes the stream.                │
└─────────────────────────────────────────────────┘
```

### How it integrates with Phoenix

1. **SSE endpoint**: A dedicated Phoenix controller (`AiStreamController`) handles `POST /api/chat` requests. It authenticates the user (session cookie or token), builds the LLM request via `AgentChat.LLM`, streams chunks from ReqLLM, and formats them per the Vercel Data Stream Protocol.

2. **React island**: The chat UI is mounted as a React island within a LiveView page via a Phoenix hook. The React component uses `useChat({ api: "/api/chat" })` to connect to the SSE endpoint.

3. **LiveView bridge**: Non-chat data (strand info, user settings, navigation) continues to flow through LiveView. The React island receives initial props from LiveView and can communicate back via custom events.

### Pros

| Advantage | Detail |
|---|---|
| **Streaming "just works"** | `useChat` handles SSE consumption, message state, buffering, reconnect — zero custom code |
| **Tool call rendering** | When the LLM calls a tool, the SDK provides a callback to render custom React components (e.g., `<LessonCard>`) instead of plain text |
| **Auto-scroll** | Built-in scroll management for chat interfaces |
| **Abort / retry** | User can abort a streaming response or retry a failed one — `useChat` handles the state transitions |
| **Model agnostic** | The SDK doesn't care what model the backend uses. It only consumes the stream protocol. |
| **Massive community** | The most widely adopted AI frontend SDK. Battle-tested patterns, extensive documentation, frequent updates. |
| **Lightweight** | The `ai` package is ~40KB. No heavy runtime. |

### Cons

| Disadvantage | Detail |
|---|---|
| **Requires React** | Lanttern is currently pure LiveView. React setup is in progress but not ready. |
| **SSE endpoint = parallel API surface** | The SSE endpoint is separate from LiveView. It needs its own authentication, CSRF protection, rate limiting. |
| **LiveView ↔ React bridge complexity** | Communicating between LiveView state and a React island requires a hook bridge layer. Complex state synchronization can be tricky. |
| **Two rendering paradigms** | The app would have LiveView for everything except chat, and React for chat. This dual-paradigm approach adds cognitive overhead. |
| **Build tooling changes** | esbuild must be configured to compile JSX, or a separate Vite pipeline is needed for the React subtree. |
| **Not needed for v0** | LiveView can deliver streaming via PubSub and rich components via function components. The SDK's value only materializes at scale or for complex interactive patterns. |

### Comparison with alternatives

| Feature | Vercel AI SDK | CopilotKit | assistant-ui |
|---|---|---|---|
| **Scope** | Frontend streaming hooks | Full platform (frontend + backend) | Headless React chat components |
| **Backend coupling** | None — any SSE backend | CopilotKit backend SDK required | None — any backend |
| **Streaming** | SSE (Data Stream Protocol) | AG-UI Protocol | Custom adapters |
| **Tool call UI** | Custom renderers per tool | Built-in action rendering | Custom renderers |
| **Complexity** | Low (just hooks) | High (full platform) | Medium (component library) |
| **Best for** | Custom backend + React frontend | Full-stack AI apps | Maximum UI customization |
| **Risk for Lanttern** | Low (focused, lightweight) | High (platform dependency, conflicts with Elixir backend) | Medium (smaller community) |

### Recommendation for Lanttern

**Short-term (Phase 1-3)**: Do not adopt the Vercel AI SDK. Use LiveView for the chat UI. The backend architecture should be designed to be UI-agnostic, so the transition to React is seamless when ready.

**Medium-term (Phase 4-5)**: Once React islands are operational, adopt the Vercel AI SDK for the chat interface. Implement a Phoenix SSE controller that speaks the Vercel Data Stream Protocol. Keep LiveView as the overall page framework, with the chat as a React island.

**Avoid CopilotKit**: Its backend SDK conflicts with Lanttern's Elixir-centric architecture. assistant-ui is a viable alternative if the team prefers more control over the UI, but Vercel AI SDK's community and documentation make it the safer bet.

---

## 4. Deep Dive: Langfuse

### What it is

Langfuse is an **open-source LLM engineering platform** (acquired by ClickHouse in 2026, 24k+ GitHub stars). Unlike general-purpose APM tools, it natively understands LLM-specific concepts: token usage, model parameters, prompt/completion pairs, evaluation scores, and conversation sessions.

### Architecture (v4 — current)

```
┌──────────────────────────────────────────────────┐
│  Langfuse Platform                                │
│                                                   │
│  ┌─────────────┐    ┌──────────────────────────┐ │
│  │   Web        │    │  Worker (Node.js)         │ │
│  │  (Next.js)   │    │  - BullMQ async queues    │ │
│  │  - UI        │    │  - Event processing       │ │
│  │  - REST API  │    │  - Evaluation pipelines   │ │
│  │  - OTLP API  │    └──────────┬───────────────┘ │
│  └──────┬───────┘               │                 │
│         │                       │                 │
│  ┌──────▼───────────────────────▼───────────────┐ │
│  │  ClickHouse (OLAP — traces, observations)     │ │
│  │  - Observation-centric data model (v4)        │ │
│  │  - Columnar format for analytical queries     │ │
│  │  - 20x faster queries than v3                 │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  PostgreSQL (metadata — users, projects)      │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  Redis/Valkey (queues + cache)                │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  S3/Blob (event persistence + exports)        │ │
│  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Core features

| Feature | What it does | Why it matters for Lanttern |
|---|---|---|
| **Distributed Tracing** | Span hierarchy: Traces > Observations (spans/generations/events). Session grouping. | Track entire conversation lifecycle: user message → prompt building → LLM call → tool execution → response. Identify bottlenecks. |
| **Prompt Management** | Version control, branching, caching, playground for testing. | Currently, prompts live in code (`agent_chat.ex`). Langfuse enables non-developer prompt iteration without deployments. |
| **Evaluation** | LLM-as-judge, manual labeling, custom eval pipelines, dataset-based regression testing. | Measure and improve agent quality over time. Answer: "Are our lesson plans getting better?" |
| **Cost Tracking** | Per-model, per-user, per-session cost calculation. Custom model pricing. | Replace the manual `llm_calls` aggregation with automated dashboards. Per-school cost visibility. |
| **User Feedback** | Collect thumbs up/down, ratings, custom feedback on AI outputs. | Close the feedback loop. Teachers rate lesson plans → data flows back to improve prompts. |
| **Analytics** | Custom dashboards, session analysis, user behavior tracking. | Understand how teachers use the agent. Which tools are called most? Where do conversations fail? |

### Self-hosting

| Option | Infrastructure | Use case |
|---|---|---|
| **Docker Compose** | Single VM, 4+ vCPUs, 16GB+ RAM. PostgreSQL + ClickHouse + Redis + Langfuse containers. | Development/staging. Not recommended for production (no HA). |
| **Kubernetes (Helm)** | K8s cluster with managed databases. Helm charts provided. Min 2 Langfuse web replicas. | Production. Full HA and auto-scaling. Can point to existing PostgreSQL/ClickHouse/Redis instances. |

**Infrastructure requirements:**
- All components must run with **UTC timezone** (non-UTC causes incorrect query results)
- Minimum: 2 web instances, auto-scale at 50% CPU
- Proper Redis/ClickHouse replication for HA

**Cost of self-hosting:**
| Scale | Infra cost/month | DevOps cost/month | Total |
|---|---|---|---|
| Small (<1M traces/mo) | $500-1,000 | ~$2,000 | ~$2,500 |
| Medium (1-10M traces/mo) | $2,000-3,000 | ~$3,000 | ~$5,000 |
| Large (10M+ traces/mo) | $5,000-15,000 | ~$5,000 | ~$10,000+ |

### Elixir integration

There is no official Elixir SDK from Langfuse. Integration options:

| Approach | Effort | Quality | Recommended? |
|---|---|---|---|
| **OpenTelemetry** | Medium | Excellent — native BEAM support, distributed tracing, standard protocol | **Yes (recommended)** |
| **REST API** | Low | Good for simple use cases. Manual batching needed. | For quick start |
| **Community SDK** (`workera-ai/langfuse_sdk`) | Low | Community-maintained, not official. Check maturity. | Evaluate before relying |

**Recommended integration pattern:**

```
Phoenix Application (Elixir)
    ↓
AgentChat.LLM (ReqLLM calls)
    ↓ wrap with OpenTelemetry spans
opentelemetry-erlang (hex package)
    ↓ OTLP export
Langfuse /api/public/otel endpoint
    ↓
ClickHouse (traces/observations)
```

**Practical implementation:**

```elixir
# In AgentChat.LLM, wrap LLM calls with telemetry
def run_completion(model, messages, tools, opts) do
  metadata = %{model: model, provider: "openai"}

  :telemetry.span([:lanttern, :llm, :call], metadata, fn ->
    result = do_llm_call(model, messages, tools, opts)

    end_metadata =
      case result do
        {:ok, response} ->
          %{tokens_in: response.usage.input, tokens_out: response.usage.output}
        {:error, _} ->
          %{error: true}
      end

    {result, Map.merge(metadata, end_metadata)}
  end)
end
```

The OpenTelemetry library subscribes to these telemetry events and exports them as spans to Langfuse's OTLP endpoint. This is non-invasive — the business code emits events, the infrastructure layer handles export.

### Pricing comparison

| Plan | Monthly | Traces/month | Per 100K extra | Users | Retention |
|---|---|---|---|---|---|
| **Hobby (Free)** | $0 | 50,000 | — | 2 | 30 days |
| **Core** | $29 | 1,000,000 | $8 | Unlimited | 90 days |
| **Pro** | $199 | 5,000,000 | $8 | Unlimited | 2 years |
| **Self-hosted** | $0 (software) | Unlimited | — | Unlimited | Unlimited |

### Recommendation for Lanttern

**Phase 1-2**: Use custom telemetry + existing `llm_calls` table. Add `:telemetry` events for LLM calls. Create an Oban cron job to aggregate costs per school.

**Phase 3**: Adopt Langfuse Cloud (free Hobby tier or $29 Core). Integrate via OpenTelemetry. Use for tracing, cost dashboards, and initial evaluation experiments.

**Phase 5+**: Evaluate self-hosted Langfuse when either (a) trace volume exceeds 5M/month, (b) data sensitivity requires on-premises, or (c) advanced features like prompt management justify the infrastructure investment.

---

## 5. Deep Dive: Microservice Architecture & Cross-Language Ecosystems

### Python AI ecosystem — What Elixir doesn't have

#### Agent Orchestration

| Framework | Status | What it does | Elixir equivalent |
|---|---|---|---|
| **LangGraph** | Production-ready (v1.0, Oct 2025) | Stateful agents with checkpointing, time-travel debugging, human-in-the-loop, 5 streaming modes, durable execution | **Nothing** — our custom tool_call_loop is ~5% of LangGraph's feature set |
| **CrewAI** | Production-ready | Multi-agent role-based teams. Define agents with roles, goals, tools, and let them collaborate. | **Nothing** — no multi-agent framework in Elixir |
| **AG2/AutoGen** | Near-ready (v1.0 coming) | Complex multi-agent scenarios with code execution, tool use, and human-in-the-loop | **Nothing** |
| **LlamaIndex** | Production-ready | RAG-first agents, document loaders, chunking, vector stores, retrieval pipelines | **Nothing** — must build RAG manually |

#### Structured Output & Validation

| Framework | Status | What it does | Elixir equivalent |
|---|---|---|---|
| **Instructor** | Production-ready (3M+ downloads/month) | Schema-first structured LLM outputs with automatic retries and validation | Ecto schema validation (manual, no LLM retry logic) |
| **Pydantic AI** | Production-ready | Type-safe agents with dependency injection, streaming, and built-in observability | Nothing equivalent |
| **DSPy** | Emerging | Automatic prompt optimization — writes and tunes prompts algorithmically | **Nothing** — unique capability |

#### Evaluation & Safety

| Framework | Status | What it does | Elixir equivalent |
|---|---|---|---|
| **DeepEval** | Production-ready | Pytest-like unit testing for LLMs — hallucination detection, relevancy scoring, toxicity checks | **Nothing** |
| **RAGAS** | Production-ready | Research-backed RAG evaluation — faithfulness, answer relevancy, context precision | **Nothing** |
| **PromptFoo** | Production-ready | Security red-teaming, prompt injection testing, harmful output detection | **Nothing** |

#### Memory Systems

| System | What it does | Elixir equivalent |
|---|---|---|
| **mem0** | Managed memory layer — auto-categorizes, vector search, user/session/agent scoping | Custom `user_ai_memories` table (simpler, but tailored) |
| **MemGPT/Letta** | Self-editing agent memory with tiered storage (core/archival/recall) | Nothing equivalent |
| **LangGraph checkpointing** | Conversation state persistence with time-travel and branching | Nothing — we use database for state |

### TypeScript AI ecosystem — The frontend-native option

| Framework | Strength | What it adds over Elixir |
|---|---|---|
| **Vercel AI SDK** | Native SSE streaming, `useChat`, tool call rendering | No Phoenix bridge needed — backend and frontend speak the same language |
| **LangChain.js** | Most comprehensive JS AI framework | RAG support, agent chains — but a port from Python, not native TS design |
| **LangGraph.js** | Same features as Python LangGraph | Stateful agents, streaming, checkpointing — in TypeScript |
| **Mastra** | TypeScript-native AI framework | Clean abstractions, built-in routing, emerging but well-funded |

### Architecture diagrams

#### Option B: Python sidecar (co-deployed)

```
┌──────────────────────────────────────────────────────────────┐
│  Same pod / VM / deployment unit                              │
│                                                               │
│  ┌─────────────────────┐     ┌─────────────────────────────┐ │
│  │  Phoenix (Elixir)    │     │  FastAPI (Python)            │ │
│  │                      │     │                              │ │
│  │  • LiveView UI       │     │  • LLM orchestration         │ │
│  │  • Scope/Auth        │     │  • LangGraph agents          │ │
│  │  • Business logic    │     │  • Streaming (SSE)           │ │
│  │  • Ecto/DB access    │     │  • Evaluation (DeepEval)     │ │
│  │  • PubSub            │     │  • Memory (mem0)             │ │
│  │  • Oban jobs         │     │                              │ │
│  │                      │◄────┤  Tool calls: POST            │ │
│  │  Internal API:       │     │  /internal/tools/create_lesson│ │
│  │  POST /internal/     │────►│                              │ │
│  │  tools/*             │     │  Context: GET                │ │
│  │                      │     │  /internal/context/:conv_id  │ │
│  └──────────┬───────────┘     └──────────────┬──────────────┘ │
│             │                                │                │
│             └──────────┬─────────────────────┘                │
│                        ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Shared PostgreSQL (+ pgvector)                          │ │
│  │  Shared Redis (Oban + FastAPI cache + PubSub bridge)     │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**Data flow for a user message (sidecar):**

```
1. User submits prompt → Phoenix LiveView
2. Phoenix saves message to DB, sets conversation "processing"
3. Phoenix calls FastAPI: POST http://localhost:8000/chat
   Body: {conversation_id, user_id, scope_token, model, tools_enabled}
4. FastAPI loads context: GET http://localhost:4000/internal/context/{conv_id}
   Phoenix returns: {system_messages, memories, tool_definitions}
5. FastAPI runs LangGraph agent with streaming
6. On tool call: FastAPI calls Phoenix: POST http://localhost:4000/internal/tools/create_lesson
   Phoenix executes with Scope auth, returns result
7. On text chunk: FastAPI publishes to Redis
   Phoenix PubSub bridge picks up → broadcasts to LiveView
8. On completion: FastAPI calls Phoenix: POST http://localhost:4000/internal/messages
   Phoenix saves assistant message + model_call to DB
```

#### Option C: Full microservice (separate deployment)

```
┌─────────────────────────┐         ┌─────────────────────────┐
│  Phoenix (Elixir)        │         │  AI Service (Python)     │
│  Deployment A            │         │  Deployment B            │
│                          │         │                          │
│  • LiveView UI           │  gRPC   │  • LangGraph agents      │
│  • Scope/Auth            │◄───────►│  • LLM orchestration     │
│  • Business logic        │  or     │  • Evaluation pipeline   │
│  • Ecto/DB              │  REST   │  • Memory management     │
│  • PubSub               │         │  • RAG (if needed)       │
│  • Oban                  │         │                          │
│                          │         │                          │
│  PostgreSQL A            │         │  PostgreSQL B (optional)  │
│  (domain data)           │         │  (AI state, vectors)     │
│                          │         │  Redis (Celery queues)   │
└─────────────────────────┘         └─────────────────────────┘
```

**Additional complexity in Option C:**
- Service discovery and health checks
- Network authentication between services
- API versioning and contract testing
- Distributed tracing across services
- Coordinated deployments (breaking changes)
- Two separate CI/CD pipelines

### Operational cost comparison

| Dimension | Option A: Elixir monolith | Option B: Python sidecar | Option C: Full microservice |
|---|---|---|---|
| **Infrastructure** | ~$5K/month | ~$5.5-6.5K/month (+10-30%) | ~$18-30K/month (3.75-6x) |
| **Engineers needed** | 2-3 Elixir | 2-3 Elixir + 1-2 Python | 2-3 Elixir + 2-4 Python + 1 platform |
| **Deployment complexity** | Single pipeline | Single pipeline (same unit) | Two pipelines + coordination |
| **Monitoring** | LiveDashboard + Oban Web | Same + FastAPI metrics | Distributed tracing required |
| **Incident response** | One codebase to debug | Two codebases, same host | Two codebases, network issues |
| **Time to first feature** | Fast (no setup) | +1-2 weeks (FastAPI setup, bridge layer) | +4-6 weeks (infra, networking, auth) |

### Hiring pool reality

| Language | Global developers | AI-specialized | Hiring difficulty for AI roles |
|---|---|---|---|
| **Python** | ~3.2M contributors | 95% of AI work | Moderate — large pool, high demand |
| **TypeScript** | ~3M contributors | ~5% of AI work | Easy (general) / Hard (AI-specific) |
| **Elixir** | ~50K contributors | <1% of AI work | Very hard — tiny pool, almost no AI specialization |

**Practical implication**: If Lanttern needs to hire an AI engineer, they will almost certainly be a Python developer. The sidecar pattern (Option B) is the natural way to integrate their expertise without rewriting the Elixir codebase.

---

## 6. Deep Dive: Choosing a Frontend Stack — CopilotKit + AG-UI vs Vercel AI SDK vs assistant-ui

### The AG-UI Protocol

AG-UI (Agent-User Interaction Protocol) is an **open standard** for agent-to-frontend communication, adopted by Google, AWS, LangChain, Microsoft, Mastra, and PydanticAI. It defines a structured SSE event format designed specifically for AI agents — not just chatbots.

**Event types:**

| Event | Purpose | Example |
|---|---|---|
| `RUN_STARTED` / `RUN_FINISHED` | Agent lifecycle tracking | Show "thinking..." indicator |
| `TEXT_MESSAGE_START` / `CONTENT` / `END` | Token streaming | Display text as it's generated |
| `TOOL_CALL_START` / `TOOL_CALL_END` | Tool execution tracking | Show "creating lesson..." with spinner |
| `STATE_SNAPSHOT` | Full agent state broadcast | Sync entire conversation state on reconnect |
| `STATE_DELTA` | Incremental state updates | Update specific UI elements in real-time |
| `STEP_STARTED` / `STEP_FINISHED` | Multi-step workflow tracking | Show progress through agent workflow |

**Comparison with Vercel Data Stream Protocol:**

| Aspect | AG-UI Protocol | Vercel Data Stream Protocol |
|---|---|---|
| **Designed for** | AI agents with complex state | Chat interfaces with text streaming |
| **State management** | First-class (snapshots + deltas) | Not supported |
| **Human-in-the-loop** | Native events for approval workflows | Not supported |
| **Tool call detail** | Start, args, progress, result, end | Start, result only |
| **Agent lifecycle** | Full lifecycle events | Done signal only |
| **Multi-step workflows** | Step tracking events | Not supported |
| **Adoption** | Google, AWS, Microsoft, LangChain | Vercel ecosystem |
| **Maturity** | Newer (2025), growing rapidly | Established (2024), widely used |

### CopilotKit — Full platform implementing AG-UI

CopilotKit is a React platform that implements the AG-UI Protocol, providing pre-built components for AI agent interfaces.

**Components:** `<CopilotChat>`, `<CopilotPopup>`, `<CopilotSidebar>`, `<CopilotTextarea>`

**Key features:**
- **Generative UI**: Agent can render custom React components inline (e.g., lesson cards, approval dialogs)
- **State synchronization**: Real-time sync between agent state and UI via STATE_SNAPSHOT/DELTA events
- **Human-in-the-loop**: Built-in approval workflows (agent pauses, shows approval UI, resumes on user action)
- **Auto-tool rendering**: Tool calls automatically render as interactive UI elements
- **LangGraph native**: Direct integration via AG-UI — no conversion layer needed

**Pros:**
- Richest agent UX out of the box — state sync, tool rendering, human-in-the-loop all work natively
- AG-UI Protocol means you're not locked into CopilotKit — any AG-UI consumer works
- Strong corporate backing (Google, AWS, Microsoft endorsements)
- Open source core

**Cons:**
- More opinionated — you use their component structure or fight it
- Freemium model (cloud features have paid tiers)
- Smaller community than Vercel AI SDK (~15k vs ~60k stars)
- Heavier dependency footprint

### assistant-ui — Headless chat components

assistant-ui is a headless React component library specifically for AI chat interfaces. It's lighter than CopilotKit and gives more control over the UI.

**Key features:**
- **LangGraphMessageAccumulator**: Efficient streaming handler for LangGraph events
- **Headless components**: You control every visual detail (unstyled by default)
- **LangGraph Cloud adapter**: Direct connection to LangGraph Cloud/Studio API
- **Rich content**: Markdown, code highlighting, attachments, voice input
- **Production UX**: Auto-scroll, retry, abort, reconnection

**Pros:**
- Maximum visual customization — headless means your design system, your rules
- Lighter than CopilotKit (focused on chat, not a platform)
- Good LangGraph integration via native adapter
- Fully open source, no paid tiers

**Cons:**
- No state synchronization (no STATE_SNAPSHOT/DELTA support)
- No built-in human-in-the-loop workflows
- No generative UI (you build custom tool renderers yourself)
- Smaller community (~5k stars)
- Less documentation for non-LangGraph-Cloud backends

### Vercel AI SDK — Lightweight streaming hooks

Already covered in [Deep Dive: Vercel AI SDK](#3-deep-dive-vercel-ai-sdk). Key additions for this comparison:

**Limitations with LangGraph backend:**
- The `@ai-sdk/langchain` adapter converts LangGraph's rich event stream into the simpler Data Stream Protocol. This conversion is **lossy** — STATE events, lifecycle events, and detailed tool progress are dropped.
- `useChat` manages messages as a flat list. LangGraph manages state as a graph with checkpoints. The mismatch means `useChat` can't expose LangGraph's most valuable features (time-travel, branching, state inspection).
- For simple chat (text + basic tool calls), this loss doesn't matter. For agent UX (status indicators, approval workflows, state sync), it does.

### Comparison table: All four options

| Dimension | CopilotKit + AG-UI | assistant-ui | Vercel AI SDK | AG-UI direct (no lib) |
|---|---|---|---|---|
| **Protocol** | AG-UI (rich events) | Custom adapters | Data Stream Protocol | AG-UI (raw) |
| **Events supported** | TEXT, TOOL_CALL, STATE, HUMAN_APPROVAL, lifecycle | TEXT, TOOL_CALL (via adapters) | Text + basic tool calls | All AG-UI events |
| **State sync** | Yes (snapshots + deltas) | No | No | Yes (manual handling) |
| **Human-in-the-loop** | Native | No | No | Yes (manual) |
| **LangGraph fit** | Native 1:1 mapping | Via LangGraphMessageAccumulator | Adapter with information loss | 1:1 (manual) |
| **Community** | ~15k stars + Google/AWS/MS | ~5k stars | ~60k stars | Open standard, emerging |
| **Complexity** | Opinionated (platform) | Headless (flexible) | Light (just hooks) | DIY (max control) |
| **UI customization** | Medium (pre-built components) | High (headless, unstyled) | Medium (hooks + custom) | Total |
| **Python backend** | Native via AG-UI Python SDK | Via LangGraph Cloud adapter | Via fastapi-ai-sdk | Native |
| **TypeScript backend** | Supported | Supported | Native | Supported |
| **Elixir backend** | Via SSE endpoint | Via SSE endpoint | Via SSE endpoint | Via SSE endpoint |
| **Pricing** | Open source + paid cloud | Open source | Open source | Open source |
| **Best for** | Complex agents, rich UX | Customizable chat | Simple chat, any backend | Full control, experienced team |

### When to use each — Application examples

**CopilotKit + AG-UI** — Best for complex agent interactions:
- Education platform where AI creates lessons and the teacher approves before saving
- CRM agent that fills forms, suggests actions, and waits for user confirmation
- Multi-agent system where the UI shows which agent is active and its current step
- IDE assistant that edits code and shows diffs inline for approval

**assistant-ui** — Best for customizable chat interfaces:
- Chat with attachments, voice input, and rich markdown rendering
- Project with an existing design system that must be applied to the chat UI
- Integration with LangGraph Cloud where the adapter handles the backend
- Chat-centric app where visual customization is more important than agent state features

**Vercel AI SDK** — Best for simple, fast-to-build chat:
- Customer support chatbot with text Q&A
- Content generation tool (write emails, summarize documents)
- Autocompletion / suggestion features
- Any chat that doesn't need rich tool call UI or agent state awareness

**AG-UI direct (no library)** — Best for maximum control:
- Team with strong React expertise that wants to consume AG-UI events directly
- Integration with non-React frameworks (Vue, Svelte, Angular)
- Edge cases where no existing library fits

### Analysis for Lanttern's requirements

| Lanttern requirement | CopilotKit | assistant-ui | Vercel AI SDK | Winner |
|---|---|---|---|---|
| Lesson card inline in chat | Native tool rendering | Custom (headless) | Custom renderer | **CopilotKit** |
| Teacher approves before lesson creation | Human-in-the-loop native | Not supported | Not supported | **CopilotKit** |
| Token streaming | Yes | Yes | Yes | Tie |
| Agent status ("creating lesson...") | STATE_DELTA events | Not supported | Not supported | **CopilotKit** |
| LangGraph backend (if Python sidecar) | Native mapping | Via adapter | Adapter with loss | **CopilotKit** |
| LiveView backend (if Elixir monolith) | SSE endpoint needed | SSE endpoint needed | SSE endpoint needed | Tie |
| Visual customization (match Lanttern design) | Medium | **High** | Medium | **assistant-ui** |
| Community & longevity | Smaller + corporate backing | Small | Large | Vercel (slight edge) |
| Setup simplicity | Medium | Simple | Simplest | Vercel |

### Recommendation for Lanttern (conditional)

**If Python sidecar is adopted (LangGraph backend):**
→ **CopilotKit + AG-UI** — The agent UX features (human-in-the-loop, state sync, tool rendering) map directly to Lanttern's requirements. The lesson approval workflow alone justifies this choice. LangGraph events flow natively through AG-UI without conversion.

**If Elixir monolith continues (no LangGraph):**
→ **Vercel AI SDK** — Lighter, simpler, sufficient for basic chat with tool calls. The agent doesn't have LangGraph's rich state events, so AG-UI's advanced features would be unused overhead.

**If still on LiveView (Phases 1-3):**
→ **Neither** — Use LiveView PubSub for streaming and Phoenix function components for rich UI. All three React options require the React islands setup. Build the backend now, choose the frontend when React is ready.

**Regardless of choice**, the backend architecture (`AgentChat.LLM`, `AgentChat.Tools`, `AgentChat.ContextResolver`) remains the same. The frontend decision is independent and reversible.

---

## 7. Target Architecture

### Architecture diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                  │
│                                                                   │
│  Phase 1-3: LiveView                                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ StrandChatLive / LessonChatLive / UniversalChatLive        │  │
│  │   └── ConversationComponent (LiveComponent)                │  │
│  │         - Message stream rendering                         │  │
│  │         - Rich inline components (lesson cards, etc.)      │  │
│  │         - Prompt form, agent/template selectors            │  │
│  │         - Handles PubSub push updates                      │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Phase 5+: React island (additive, not replacing)                 │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ChatIsland (React + Vercel AI SDK)                         │  │
│  │   - useChat() connected to /api/chat SSE endpoint          │  │
│  │   - Custom tool call renderers (LessonCard, etc.)          │  │
│  │   - Auto-scroll, abort, retry                              │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
          ┌────────────────────┼─────────────────────┐
          │ 1. User submits    │ 6. PubSub broadcast  │ (or SSE for React)
          │    prompt          │    {:message_added}   │
          ▼                    │                       │
┌──────────────────────────────┴───────────────────────────────────┐
│                      CONTEXT LAYER                                │
│                                                                   │
│  Lanttern.AgentChat (context module)                              │
│    - create_conversation_with_message/3                           │
│    - add_user_message/3                                           │
│    - add_assistant_message/3                                      │
│    - list_conversation_messages/2                                 │
│    - subscribe/broadcast PubSub                                   │
│                                                                   │
│  Lanttern.AgentChat.LLM (NEW — LLM abstraction)                  │
│    - run_completion/4  (replaces run_llm_chain)                   │
│    - stream_completion/4  (Phase 4)                               │
│    - build_messages/3                                             │
│    - tool_call_loop/3  (replaces LangChain while_needs_response)  │
│    - extract_response/1                                           │
│    → Uses ReqLLM internally. NO LLM types leak outside.          │
│                                                                   │
│  Lanttern.AgentChat.Tools (NEW — tool registry)                   │
│    - define_tools/2  (returns tool specs for LLM)                 │
│    - execute_tool/3  (dispatches to business context functions)    │
│    - Tools: create_lesson, update_lesson, set_conversation_title  │
│                                                                   │
│  Lanttern.AgentChat.Memory (NEW — Phase 3)                        │
│    - list_user_memories/2                                         │
│    - create_memory/2                                              │
│    - summarize_conversation/2                                     │
│    - inject_memory_messages/2                                     │
│                                                                   │
│  Lanttern.AgentChat.ContextResolver (NEW — Phase 2)               │
│    - resolve/1  (conversation_id -> system messages)              │
│    - register_context/3                                           │
│    - context_to_system_messages/1  (per context_type)             │
└──────────────────────────────┬───────────────────────────────────┘
                               │
          ┌────────────────────┼─────────────────────┐
          │ 2. Oban.insert()   │ 5. AgentChat         │
          │                    │    .add_assistant_msg  │
          ▼                    │    .broadcast          │
┌──────────────────────────────┴───────────────────────────────────┐
│                      WORKER LAYER                                 │
│                                                                   │
│  Lanttern.ChatResponseWorker (Oban, queue: :ai)                   │
│    1. Resolve scope from user_id                                  │
│    2. Resolve model (args → school config → app default)          │
│    3. Fetch conversation + messages                               │
│    4. Inject memory  (AgentChat.Memory — Phase 3)                 │
│    5. Resolve context (AgentChat.ContextResolver — Phase 2)       │
│    6. Call AgentChat.LLM.run_completion/4                         │
│    7. Handle tool calls via AgentChat.Tools                       │
│    8. Persist response + model call                               │
│    9. Broadcast via PubSub                                        │
│   10. Trigger memory update (Phase 3)                             │
│                                                                   │
│  Lanttern.MemorySummaryWorker (NEW — Phase 3, Oban, queue: :ai)   │
│    - Triggered after conversation ends                            │
│    - Summarizes conversation into memory entries                  │
│                                                                   │
│  Lanttern.CostAggregationWorker (NEW — Phase 4, Oban cron)        │
│    - Periodic aggregation of llm_calls for cost reporting         │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               │ 3. ReqLLM.generate_text/3
                               │    (or stream_text/3 in Phase 4)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LLM CLIENT LAYER                            │
│                                                                   │
│  ReqLLM (unified, Req-based)                                      │
│    - OpenAI, Anthropic, Google, Mistral, Groq, AWS Bedrock...     │
│    - Tool calling support                                         │
│    - Streaming SSE support                                        │
│    - Req middleware for retries, logging, telemetry                │
│                                                                   │
│  LLMDB (model validation catalog)                                 │
│    - LLMDB.allowed?/1                                             │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               │ 4. Telemetry events
                               │    [:lanttern, :llm, :call, ...]
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY LAYER                            │
│                                                                   │
│  Phase 1-2: Telemetry + llm_calls table + LiveDashboard           │
│  Phase 3+:  OpenTelemetry → Langfuse (Cloud or self-hosted)       │
└─────────────────────────────────────────────────────────────────┘
```

### Module boundary rules

| Module | Responsibility | Depends On | Does NOT depend on |
|---|---|---|---|
| `AgentChat` | Data access (CRUD), PubSub | Ecto, PubSub | ReqLLM, any LLM library |
| `AgentChat.LLM` | LLM interaction: prompts, completion, tool loop | ReqLLM, LLMDB | Ecto, PubSub, Oban |
| `AgentChat.Tools` | Tool definitions and execution dispatch | Business contexts (Lessons, etc.) | ReqLLM, Ecto |
| `AgentChat.Memory` | Memory CRUD, summarization, injection | Ecto, AgentChat.LLM (for summarization) | PubSub, Oban |
| `AgentChat.ContextResolver` | Polymorphic context resolution | Ecto, business contexts | LLM, PubSub |
| `ChatResponseWorker` | Orchestration: ties all modules together | All AgentChat modules | LiveView |
| `ConversationComponent` | UI rendering, user interaction | AgentChat (context only) | LLM, Tools, Memory, Worker |

**Critical boundary**: No LLM library types leak outside `AgentChat.LLM`. The context module works with plain Elixir strings and maps. If ReqLLM is replaced later, only `AgentChat.LLM` changes.

---

## 8. Database Schema Evolution

### Phase 1: Polymorphic conversation contexts

```sql
-- Replace strand_agent_conversations with polymorphic context links
CREATE TABLE conversation_contexts (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT NOT NULL REFERENCES agent_conversations(id) ON DELETE CASCADE,
  context_type VARCHAR(50) NOT NULL,
  context_id BIGINT NOT NULL,
  context_metadata JSONB DEFAULT '{}',
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_conversation_contexts_unique
  ON conversation_contexts(conversation_id, context_type, context_id);

CREATE INDEX idx_conversation_contexts_type_id
  ON conversation_contexts(context_type, context_id);
```

**Data migration**: Migrate `strand_agent_conversations` rows into `conversation_contexts`:
- Each row becomes 1 or 2 `conversation_contexts` rows (`context_type: "strand"` + optionally `context_type: "lesson"`)
- Leave `strand_agent_conversations` as-is (tech debt, per CLAUDE.md rule 7)

### Phase 2: Message metadata + user memory

```sql
-- Rich message metadata (tool calls, UI components)
ALTER TABLE agent_messages ADD COLUMN metadata JSONB DEFAULT '{}';

-- User AI memory
CREATE TABLE user_ai_memories (
  id BIGSERIAL PRIMARY KEY,
  profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  school_id BIGINT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL DEFAULT 'general',
  summary TEXT NOT NULL,
  source_type VARCHAR(50) NOT NULL DEFAULT 'conversation',
  source_id BIGINT,
  relevance_score FLOAT DEFAULT 1.0,
  expires_at TIMESTAMP,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_ai_memories_profile ON user_ai_memories(profile_id);
CREATE INDEX idx_user_ai_memories_school ON user_ai_memories(school_id);
```

**Message metadata structure:**

```json
{
  "tool_calls": [
    {"name": "create_lesson", "args": {"moment_id": 1, "description": "..."}}
  ],
  "tool_results": [
    {"name": "create_lesson", "result": {"lesson_id": 42, "status": "ok"}}
  ],
  "ui_component": "lesson_card",
  "ui_data": {"lesson_id": 42, "lesson_name": "Introduction to Fractions"}
}
```

### Phase 3: Cost tracking aggregation

```sql
CREATE TABLE ai_usage_reports (
  id BIGSERIAL PRIMARY KEY,
  school_id BIGINT NOT NULL REFERENCES schools(id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  total_prompt_tokens BIGINT DEFAULT 0,
  total_completion_tokens BIGINT DEFAULT 0,
  total_estimated_cost_cents INTEGER DEFAULT 0,
  model_breakdown JSONB DEFAULT '{}',
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_ai_usage_reports_school_period
  ON ai_usage_reports(school_id, period_start, period_end);
```

### Phase 4: Token budget configuration

```sql
-- Add to existing school_ai_configs table
ALTER TABLE school_ai_configs ADD COLUMN monthly_token_budget BIGINT;
ALTER TABLE school_ai_configs ADD COLUMN budget_alert_threshold FLOAT DEFAULT 0.8;
```

---

## 9. Implementation Roadmap

### Phase 1: Library Consolidation + LLM Abstraction (~2 weeks)

**Goal**: Remove LangChain dependency; establish clean module boundaries.

| Step | Task | Files affected | Risk |
|---|---|---|---|
| 1.1 | Create `Lanttern.AgentChat.LLM` module with `run_completion/4` wrapping ReqLLM | New: `lib/lanttern/agent_chat/llm.ex` | Low |
| 1.2 | Create `Lanttern.AgentChat.Tools` module; extract tool definitions from `agent_chat.ex` | New: `lib/lanttern/agent_chat/tools.ex`; Modified: `agent_chat.ex` | Low |
| 1.3 | Implement tool call loop in `AgentChat.LLM` (replaces `while_needs_response`) | `agent_chat/llm.ex` | **Medium** — must handle multi-turn tool calls correctly |
| 1.4 | Rewrite `run_llm_chain/4` to use `AgentChat.LLM.run_completion/4` | `agent_chat.ex` | Medium |
| 1.5 | Rewrite `ChatResponseWorker` to use `AgentChat.LLM` instead of `ChatOpenAI` | `workers/chat_response_worker.ex` | Medium |
| 1.6 | Rewrite `rename_conversation_based_on_chain/3` to use `AgentChat.LLM` | `agent_chat.ex` | Low |
| 1.7 | Update tests: replace LangChain Mimic mocks with ReqLLM stubs | Test files | Medium |
| 1.8 | Remove `{:langchain, "0.4.0"}` from `mix.exs`; remove LangChain config | `mix.exs`, `config/*.exs` | Low |
| 1.9 | Add `:telemetry` events for LLM calls | `agent_chat/llm.ex` | Low |

**Deliverable**: All AI features work identically to today, but backed by ReqLLM through the `AgentChat.LLM` abstraction. LangChain removed from deps.

**Verification**:
- All existing tests pass
- Manual test: create a conversation, send a message, verify response
- Manual test: use create_lesson tool, verify lesson is created
- Manual test: verify auto-rename works
- `mix deps` shows no LangChain dependency

### Phase 2: Universal Context + Rich Messages (~2 weeks)

**Goal**: Polymorphic context system; message metadata for rich UI.

| Step | Task |
|---|---|
| 2.1 | Create `conversation_contexts` migration and Ecto schema |
| 2.2 | Create `Lanttern.AgentChat.ContextResolver` module |
| 2.3 | Write data migration from `strand_agent_conversations` to `conversation_contexts` |
| 2.4 | Add `metadata` JSONB column to `agent_messages` |
| 2.5 | Modify `ChatResponseWorker` to use `ContextResolver` for system prompt building |
| 2.6 | When tools execute (e.g., `create_lesson`), store entity reference in message metadata |
| 2.7 | Modify `ConversationComponent` to render rich inline components based on `message.metadata` |
| 2.8 | Create lesson card inline component for conversation stream |

**Deliverable**: Conversations can be linked to any entity type. Tool call results render as rich UI components (lesson cards) instead of plain text.

**Verification**:
- Existing strand conversations continue to work (data migration verified)
- New conversations create `conversation_contexts` rows
- When AI creates a lesson, a lesson card appears inline in the chat
- Context resolver loads correct system messages per entity type

### Phase 3: Memory System (~2 weeks)

**Goal**: Cross-conversation user memory.

| Step | Task |
|---|---|
| 3.1 | Create `user_ai_memories` migration and Ecto schema |
| 3.2 | Create `Lanttern.AgentChat.Memory` module |
| 3.3 | Create `Lanttern.MemorySummaryWorker` Oban job |
| 3.4 | Add Layer 0 memory injection to prompt construction |
| 3.5 | Add conversation close/checkpoint logic that triggers memory summarization |
| 3.6 | Add memory management page (staff can view/delete own memories) |
| 3.7 | Integrate Langfuse Cloud (OpenTelemetry or REST API) |

**Deliverable**: The agent remembers user preferences and past interactions across conversations. Langfuse provides tracing and cost dashboards.

**Verification**:
- Complete a conversation, then start a new one — agent references information from the previous conversation
- Memory entries visible in staff settings
- Deleting a memory removes it from future prompts
- Langfuse dashboard shows traces with token counts

### Phase 4: Streaming + Cost Controls (~2 weeks)

**Goal**: Real-time token streaming; usage limits.

| Step | Task |
|---|---|
| 4.1 | Add streaming path to `AgentChat.LLM` using ReqLLM streaming |
| 4.2 | Add PubSub chunk events (`{:chunk, text}`) |
| 4.3 | Update `ConversationComponent` for incremental message rendering |
| 4.4 | Create `ai_usage_reports` table and `CostAggregationWorker` |
| 4.5 | Add `monthly_token_budget` to `school_ai_configs` |
| 4.6 | Add budget enforcement check before LLM calls |
| 4.7 | Add usage dashboard for school admins |

**Deliverable**: Streaming AI responses. Schools can set token budgets. Usage reporting.

**Verification**:
- Tokens appear as they are generated (no more waiting for full response)
- Budget enforcement prevents calls when budget is exceeded
- Usage dashboard shows per-school, per-model cost breakdown

### Phase 5: File Uploads + React Evaluation (Sprint 5+)

**Goal**: Support file-based context; evaluate React for chat UI.

| Step | Task |
|---|---|
| 5.1 | Add file upload support to conversation (LiveView uploads) |
| 5.2 | PDF/document text extraction for context injection |
| 5.3 | Create Phoenix SSE controller for Vercel AI SDK Data Stream Protocol |
| 5.4 | Create chat React island with Vercel AI SDK `useChat` hook |
| 5.5 | Evaluate Langfuse self-hosted deployment |
| 5.6 | Implement ILP cooldown enforcement server-side |

**Deliverable**: File uploads work. React chat island available alongside LiveView version.

---

## 10. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| ReqLLM tool call API does not support multi-turn loop | Medium | **High** | Verify ReqLLM tool calling API in Phase 1 Step 1.3 before committing. Fallback: implement raw HTTP tool call loop (ReqLLM is just Req under the hood). |
| Token extraction from ReqLLM differs from LangChain metadata format | Medium | Low | Write adapter in `AgentChat.LLM` that normalizes response format. Isolated by design. |
| Memory summarization produces low-quality summaries | Medium | Medium | Start with simple extractive summaries. Iterate on prompt quality. Cap memory size. Allow users to delete bad memories. |
| Polymorphic context table causes query complexity | Low | Low | Index on `(context_type, context_id)`. Queries are always scoped by `conversation_id` (indexed FK). |
| LiveView streaming has perceptible latency vs SSE | Low | Low | PubSub broadcast is sub-millisecond within the same node. Acceptable UX. |
| ReqLLM library becomes unmaintained | Low | **High** | The abstraction layer (`AgentChat.LLM`) isolates the app — replacement affects exactly one module. |
| React islands setup takes longer than expected | Medium | Low | Architecture is UI-agnostic by design. LiveView path continues to work regardless of React timeline. |
| Langfuse integration complexity with Elixir | Medium | Medium | Start with REST API (simpler). Graduate to OpenTelemetry when comfortable. Community SDK as bridge option. |
| Breaking changes when migrating away from LangChain | Low | Medium | Migration is a rewrite of 2 files, not a refactor of the whole app. Comprehensive tests validate behavior. |
| Tool call loop has edge cases (timeout, partial execution) | Medium | Medium | Copy LangChain's battle-tested timeout pattern (5 min). Add structured error handling. Test with simulated slow tool calls. |
