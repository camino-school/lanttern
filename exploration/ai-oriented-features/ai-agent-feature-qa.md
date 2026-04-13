# AI Agent Architecture — Questions & Answers

> Companion document to `ai-agent-feature-plan.md`
>
> Anticipated questions from the development team about the architectural decisions, trade-offs, and implementation details.

---

## Table of Contents

1. [LLM Client Layer (LangChain → ReqLLM)](#1-llm-client-layer)
2. [Agent Orchestration (Oban)](#2-agent-orchestration)
3. [Chat UI & Frontend (LiveView → React)](#3-chat-ui--frontend)
4. [Streaming](#4-streaming)
5. [User Memory](#5-user-memory)
6. [Universal Conversation Context](#6-universal-conversation-context)
7. [Observability (Langfuse)](#7-observability)
8. [Migration & Rollback](#8-migration--rollback)
9. [Testing](#9-testing)
10. [Performance & Cost](#10-performance--cost)
11. [Security & Data Ownership](#11-security--data-ownership)
12. [Timeline & Prioritization](#12-timeline--prioritization)
13. [Vercel AI SDK Specifics](#13-vercel-ai-sdk-specifics)
14. [Langfuse Specifics](#14-langfuse-specifics)
15. [Jido Ecosystem](#15-jido-ecosystem)
16. [Monolith vs Microservice](#16-monolith-vs-microservice)
17. [CopilotKit vs Vercel AI SDK vs assistant-ui](#17-copilotkit-vs-vercel-ai-sdk-vs-assistant-ui)

---

## 1. LLM Client Layer

### Q: Why remove LangChain instead of removing ReqLLM? LangChain has more features.

LangChain has more features, but most of them are not used by Lanttern. The only LangChain features we actually use are:

1. `LLMChain` with `while_needs_response` — a tool-call loop (~25 lines of custom code to replace)
2. `ChatOpenAI` — model instantiation (one line with ReqLLM)
3. `Function`/`FunctionParam` — tool definitions (simpler in ReqLLM with `ReqLLM.Tool`)
4. `Message` constructors — message building (direct equivalent in `ReqLLM.Context`)

We're paying for an entire framework but using ~5% of it. ReqLLM is leaner, already in the project, already tested, natively supports 10+ providers, and follows Elixir conventions more closely. The cost of keeping LangChain (cognitive overhead of two libraries, two test patterns, two configs) outweighs the cost of rewriting 25 lines of orchestration code.

### Q: What exactly is the "tool call loop" we need to build ourselves? Isn't that complex?

The tool call loop replaces LangChain's `mode: :while_needs_response`. Here's what it does:

1. Send messages + tool definitions to the LLM
2. If the LLM response contains a tool call → execute the tool → append the result to messages → go back to step 1
3. If the LLM response is plain text → return it

In pseudocode:

```elixir
def tool_call_loop(model, messages, tools, opts, max_iterations \\ 10) do
  case call_llm(model, messages, tools, opts) do
    {:ok, %{tool_calls: []}} = result ->
      result

    {:ok, %{tool_calls: tool_calls} = response} when max_iterations > 0 ->
      results = Enum.map(tool_calls, &execute_tool/1)
      updated_messages = messages ++ [assistant_msg(response)] ++ tool_result_msgs(results)
      tool_call_loop(model, updated_messages, tools, opts, max_iterations - 1)

    {:ok, _} ->
      {:error, :max_iterations_exceeded}

    error ->
      error
  end
end
```

It's roughly 25-30 lines. The `max_iterations` guard prevents infinite loops. The 5-minute timeout from LangChain is replaced by a timeout on the `call_llm` function itself.

### Q: What if ReqLLM doesn't support tool calling the way we need?

ReqLLM v1.6+ supports tool calling via `ReqLLM.Tool`. The API is:

```elixir
tools = [
  ReqLLM.Tool.function("create_lesson", "Creates a lesson plan", %{
    type: "object",
    properties: %{
      description: %{type: "string", description: "Lesson description"},
      moment_id: %{type: "integer", description: "The moment ID"}
    },
    required: ["description", "moment_id"]
  })
]

{:ok, response} = ReqLLM.generate_text(model, context, tools: tools)
```

If ReqLLM's tool calling doesn't handle a specific edge case, ReqLLM is built on Req (a composable HTTP client). We can always drop to the raw HTTP layer and send the tool call parameters directly to the provider's API. This is a safety net, not an expected path.

**Verification step**: Phase 1 Step 1.3 explicitly includes verifying ReqLLM's tool calling API before committing to the migration. If it doesn't work, we build a thin wrapper around Req that handles the OpenAI tool calling protocol directly.

### Q: ReqLLM supports 10+ providers, but do we actually need that? We only use OpenAI.

Today, yes. But the plan explicitly identifies **single provider lock-in** as a current gap. Schools may want to use different models (Anthropic for creative tasks, Google for multilingual, local models for data-sensitive schools). The abstraction layer (`AgentChat.LLM`) combined with ReqLLM's multi-provider support means switching providers is a configuration change, not a code change.

Even if we stay on OpenAI for the next 6 months, the cost of multi-provider support is zero — ReqLLM already provides it. It's not something we're building; it's something we get for free.

### Q: Won't removing LangChain break the existing tests?

Yes, existing tests that mock LangChain (via `Mimic.copy(LangChain.Chains.LLMChain)`) will need to be rewritten. This is Phase 1 Step 1.7. The new tests will use the same `ReqLLMStub` pattern already established for the ILP feature — dependency injection of the LLM module, not library-specific mocks.

The test rewrite is actually an improvement: dependency injection is more reliable and simpler than Mimic-based mocking. The test surface is contained to `agent_chat_test.exs` and `chat_response_worker_test.exs`.

### Q: What about the LangChain Elixir ecosystem evolving? What if it gets much better?

LangChain for Elixir (v0.4.0) is a community port of the Python/JS LangChain ecosystem. Its update cadence is unclear and it doesn't follow Elixir idioms closely. Even if it improves, our architecture isolates the LLM client inside `AgentChat.LLM` — if a better library emerges (LangChain, Jido, or something new), we change one module, not the entire app.

The architectural decision is not "ReqLLM forever" — it's "one library now, behind an abstraction that makes switching cheap."

---

## 2. Agent Orchestration

### Q: Why not use Jido agents instead of Oban? Jido is designed specifically for AI agents.

Jido v2.0 introduces GenServer-based agents with state management, directives, and runtime execution. These are powerful features — for the right problem. Our current problem doesn't need them.

Lanttern's agent chat is stateless between requests: the user sends a message, the system processes it, stores the result, and broadcasts it. All state lives in PostgreSQL. There's no need for in-memory agent state, multi-agent coordination, or complex state machines.

Jido would add:
- New supervision tree to manage
- New deployment considerations (agent process lifecycle)
- New testing patterns (GenServer testing vs Oban job testing)
- New concepts for the team to learn (directives, signals, command function)

For zero benefit over what Oban already provides (retries, unique constraints, pruning, dashboard, test isolation).

**When Jido makes sense**: If we ever need agents that coordinate with each other, hold long-running state, or execute complex multi-step workflows where the state machine is not trivially representable in a database. That day may come — but it's not today.

### Q: If we add streaming with Task.Supervisor (Phase 4), won't we have two execution paths? Isn't that messy?

Yes, there will be two paths. But they serve different purposes:

1. **Oban path** (non-streaming): Reliable, retryable, job-based. Used for the main LLM call. Survives server restarts. Has unique constraints. Records in Oban dashboard.
2. **Task path** (streaming): Fire-and-forget within a request lifecycle. Streams chunks via PubSub. Does not survive restarts (but streaming is inherently tied to an active connection).

The worker decides which path to use:

```elixir
def perform(%Oban.Job{args: %{"streaming" => true} = args}) do
  # Spawn a supervised Task that streams chunks via PubSub
  Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
    stream_response(args)
  end)
end

def perform(%Oban.Job{args: args}) do
  # Regular batch processing (current behavior)
  batch_response(args)
end
```

This is not two competing architectures — it's one orchestrator (Oban) with two execution strategies. The complexity is contained in the worker module.

### Q: What happens if the Oban job fails during a tool call?

The current behavior is preserved: Oban retries the job (up to `max_attempts: 3`). The tool call is idempotent by design — if `create_lesson` is called twice with the same parameters, the second call either creates a duplicate (which the user can delete) or fails if there's a uniqueness constraint.

For non-idempotent operations, the tool call result should be stored in the database before broadcasting. On retry, the worker checks if the tool call was already executed (by checking message metadata) and skips re-execution.

---

## 3. Chat UI & Frontend

### Q: The React setup is already in progress. Why not wait and go directly to React + Vercel AI SDK?

Three reasons:

1. **Timeline risk**: The React setup timeline is uncertain. Blocking AI backend architecture on frontend infrastructure would delay the entire project.
2. **Backend-first architecture**: The backend (LLM abstraction, context resolution, memory, tools) is the same regardless of frontend technology. Building it now with LiveView means it's ready for React when React is ready.
3. **LiveView is sufficient for v0**: The chat needs to display messages, show loading states, render tool call results as inline components, and (later) stream tokens. LiveView handles all of this natively. The value of Vercel AI SDK is in convenience (auto-scroll, abort, reconnect) — nice to have, not blocking.

The transition plan is explicit: **Phase 1-3 = LiveView; Phase 4-5 = React island added alongside LiveView**. Both paths coexist. No rip-and-replace.

### Q: If we go with LiveView now, won't we have to rewrite the entire chat UI when we move to React?

No. The rewrite is only the **template layer** (HTML/HEEx → JSX). The backend contract doesn't change:

- `AgentChat` context functions: same API regardless of consumer
- PubSub events: same events whether consumed by LiveView or forwarded to SSE
- Message schema: same `metadata` JSONB regardless of how it's rendered
- Tool definitions: same `AgentChat.Tools` module

What changes when adding React:
1. A new Phoenix controller (`AiStreamController`) that converts PubSub events to SSE
2. A React component that uses `useChat` to consume the SSE stream
3. A LiveView hook that mounts the React island

What does NOT change: `AgentChat`, `AgentChat.LLM`, `AgentChat.Tools`, `AgentChat.Memory`, `AgentChat.ContextResolver`, `ChatResponseWorker`, `MemorySummaryWorker`, all Ecto schemas, all migrations.

### Q: Why Vercel AI SDK over CopilotKit? CopilotKit seems more feature-complete.

CopilotKit is a **full platform** — it includes a backend SDK, its own agent orchestration (AG-UI Protocol), and a cloud offering. Adopting CopilotKit means:

1. **Backend conflict**: CopilotKit expects you to use its backend SDK for agent communication. Lanttern's agent logic lives in Elixir (Oban workers, ReqLLM, Phoenix PubSub). CopilotKit's Node.js backend SDK doesn't integrate with this.
2. **Vendor lock-in**: CopilotKit has a freemium model with paid enterprise tiers. The AI SDK is fully open source.
3. **Over-engineering**: We don't need a platform. We need a streaming chat hook. Vercel AI SDK is exactly that — `useChat()` and nothing more.

CopilotKit makes sense for teams building a new app with AI at the core and no existing backend. Lanttern has a mature Elixir backend. Adding CopilotKit's backend on top would create a parallel system that fights with Oban/PubSub.

### Q: What about assistant-ui? It seems more customizable than Vercel AI SDK.

assistant-ui is a headless React component library specifically for AI chat UIs. It's a good library with fine-grained control over every UI element. The trade-offs vs Vercel AI SDK:

| Aspect | Vercel AI SDK | assistant-ui |
|---|---|---|
| **Community** | ~60k GitHub stars, massive adoption | ~5k stars, growing |
| **Documentation** | Extensive, covers non-Next.js backends | Good, but less coverage for custom backends |
| **Backend protocol** | Well-defined Data Stream Protocol | Custom adapters (more flexible, more work) |
| **Streaming** | Built-in via useChat | Requires adapter configuration |
| **Risk** | Very low (Vercel backing, industry standard) | Low-medium (smaller community) |

Both are viable. The recommendation is Vercel AI SDK because its Data Stream Protocol is well-documented for custom backends (which is our case — Phoenix, not Next.js), and the community size provides confidence in long-term maintenance.

If the team evaluates both during Phase 5 and prefers assistant-ui's flexibility, the backend doesn't change. The SSE endpoint serves the same protocol either way.

### Q: Could we use LiveView for everything including streaming and skip React entirely?

Yes, technically. LiveView can stream tokens via PubSub, render rich components, and handle all chat interactions. The question is whether the team wants to invest in building:

- Auto-scroll logic (scroll to bottom as tokens arrive, but not if user scrolled up)
- Abort handling (cancel an in-progress LLM call)
- Reconnection logic (what happens when the WebSocket drops mid-stream?)
- Optimistic message display (show user message immediately before server confirmation)
- Keyboard shortcuts (submit on Enter, newline on Shift+Enter with proper cursor handling)

These are all solved problems in Vercel AI SDK. Building them in LiveView is possible but time-consuming. The recommendation is: **LiveView for now, React for when the UX investment justifies it.**

---

## 4. Streaming

### Q: Won't PubSub streaming add latency compared to direct SSE?

PubSub broadcast within the same Erlang node is sub-millisecond. The path is:

```
ReqLLM chunk → Worker process → PubSub.broadcast → Parent LiveView → send_update → Component re-render
```

Total additional latency vs direct SSE: ~1-5ms. Imperceptible to the user. The bottleneck is always the LLM API response time (typically 50-500ms per chunk), not the internal broadcast.

If Lanttern scales to multiple nodes, PubSub works across nodes via `Phoenix.PubSub` with a distributed adapter (e.g., `Phoenix.PubSub.PG2`, already configured). No code changes needed.

### Q: How do we handle tool calls during streaming? The LLM pauses, calls a tool, and resumes.

During streaming, the flow is:

1. LLM streams text tokens → broadcast as `:chunk` events
2. LLM emits a tool call → broadcast as `:tool_call_start`
3. Worker pauses the stream, executes the tool
4. Broadcast `:tool_call_result` with the result
5. Feed the result back to the LLM → streaming resumes from step 1

The ConversationComponent handles this by showing:
- Streaming text as it arrives (`:chunk`)
- A "calling tool..." indicator when `:tool_call_start` is received
- The tool result (e.g., a lesson card) when `:tool_call_result` is received
- Continued streaming text after the tool call completes

This is a sequential process — the worker manages the stream lifecycle. The component just reacts to events.

### Q: What if the user navigates away during streaming? Are tokens lost?

When the user navigates away, the LiveView process terminates and unsubscribes from PubSub. The worker (Oban job or Task) continues to completion regardless — it doesn't know or care about the subscriber.

The complete message is persisted to the database when the stream finishes (`:message_complete` event). When the user returns to the conversation, all messages (including the one that was streaming) are loaded from the database. No data is lost.

Partial messages (the streaming buffer) are lost from the UI but not from the conversation. The database is the source of truth, not the LiveView state.

---

## 5. User Memory

### Q: How do we prevent the memory system from injecting stale or wrong information?

Three safeguards:

1. **Relevance scoring**: Memories have a `relevance_score` (0.0-1.0). The summarization prompt instructs the LLM to assign lower scores to time-sensitive information. Only the top N memories (by score) are injected.

2. **Expiration**: Time-bounded memories have an `expires_at` field. A cron job prunes expired entries. Example: "The user is working on a fractions unit" expires after 30 days.

3. **Manual control**: Staff can view and delete their own memories via a settings page. If the agent says something wrong based on a memory, the user can fix it directly.

Additionally, memories are injected as context, not as facts. The system prompt wrapper makes this clear:

```xml
<user_memory>
  <note>The following is a summary of previous interactions. It may be outdated.
  Use as context, not as ground truth. If the user contradicts a memory,
  trust the user.</note>
  <preferences>User prefers detailed lesson plans with differentiation notes</preferences>
</user_memory>
```

### Q: Won't the summarization LLM call add cost for every conversation?

Yes, but it's a single, small LLM call per conversation close — not per message. The input is the conversation transcript (typically 5-20 messages), and the output is 2-3 compact summary sentences. Cost estimate:

- Input: ~2,000 tokens (conversation transcript)
- Output: ~200 tokens (summary)
- Model: Can use a cheaper/smaller model (e.g., GPT-4o-mini)
- Cost per summarization: ~$0.001

For a school with 50 active teachers, each having 5 conversations per week: 250 summarizations × $0.001 = **$0.25/week**. Negligible.

### Q: What's the difference between user memory and conversation context?

| Aspect | User Memory | Conversation Context |
|---|---|---|
| **Scope** | Cross-conversation, per-user | Single conversation, per-entity |
| **Persistence** | Survives after conversation ends | Tied to conversation lifecycle |
| **Content** | Summaries of past interactions, preferences | Curriculum data (strand, lesson, ILP details) |
| **Source** | AI-generated from conversations | Loaded from database entities |
| **Layer** | Layer 0 (before school config) | Layer 5 (curriculum context) |
| **Example** | "User prefers hands-on activities" | "Strand: Introduction to Fractions, Year 4" |

Memory tells the agent **who** the user is. Context tells the agent **what** the conversation is about.

### Q: Can memories be shared between schools if a teacher works at multiple schools?

No. Memories are scoped to `(profile_id, school_id)`. A teacher at School A and School B has separate memory sets. This is intentional:

1. **Data isolation**: Schools own their data. A memory generated from School A's curriculum should not leak to School B.
2. **Relevance**: Teaching context varies by school. "Prefers Portuguese-language lesson plans" might be relevant at one school but not another.
3. **Scope pattern**: This follows Lanttern's existing `Scope` authorization pattern — all school-scoped data is isolated by `school_id`.

---

## 6. Universal Conversation Context

### Q: Why a polymorphic table instead of a separate join table per context type?

A separate join table per type (like the current `strand_agent_conversations`) requires:
- A new migration for each new context type
- A new Ecto schema for each join table
- New query functions in the context module
- Conditional logic to check multiple tables when loading conversation contexts

The polymorphic table requires:
- One migration (done once)
- One Ecto schema
- One query to load all contexts for a conversation
- One new function clause per context type (in `ContextResolver`)

The polymorphic approach scales with the number of entity types without schema changes. Adding "assessment" or "student" context is a code change, not a database change.

**Trade-off**: We lose database-level foreign key integrity on `context_id`. This is acceptable because:
1. Context links are created programmatically (not via user input), so invalid references are programmer errors, not user errors
2. The `ContextResolver` validates the entity exists when resolving — a dangling reference produces a soft error (context not loaded), not a crash
3. This pattern is well-established in Elixir/Ecto (e.g., polymorphic embeds, Activity streams)

### Q: What happens to the old `strand_agent_conversations` table?

Per CLAUDE.md rule 7 (default is tech debt, not refactoring):

1. The data is **migrated** to `conversation_contexts` (one row per strand, optionally one per lesson)
2. The old table is **left as-is** — not dropped, not modified
3. New code uses `conversation_contexts` exclusively
4. Old code that reads `strand_agent_conversations` continues to work (until it's eventually cleaned up)

There is no breaking change. The old table becomes unused tech debt, cleaned up in a future sprint.

### Q: How does `context_metadata` JSONB work? When is it useful?

`context_metadata` stores a **snapshot** of the entity's relevant data at the time the conversation was created. Two use cases:

1. **Audit**: After the conversation, we can see exactly what the agent knew. If a strand's curriculum items change, the metadata shows the version the agent saw.

2. **Entity deletion**: If a lesson is deleted after a conversation about it, the metadata preserves the lesson's name and details for historical context.

The metadata is optional. For most cases, the `ContextResolver` loads the entity live from the database. The metadata is a safety net, not a primary data source.

### Q: Can a single conversation have contexts from different schools?

No. Conversations are scoped to `school_id` (via `agent_conversations.school_id`). All context entities must belong to the same school. The `ContextResolver` enforces this:

```elixir
def register_context(%Scope{school_id: school_id}, conversation, context_type, context_id) do
  # Verify the entity belongs to the same school as the conversation
  entity = load_entity(context_type, context_id)
  true = entity.school_id == school_id
  # ... create conversation_context
end
```

This follows the `Scope` pattern — school isolation is enforced at every boundary.

---

## 7. Observability

### Q: Why not start with Langfuse from day one? Why the phased approach?

Three reasons:

1. **Premature optimization**: In Phase 1-2, we're consolidating libraries and building abstractions. The LLM call volume is low (POC with limited users). The existing `llm_calls` table + `:telemetry` events are sufficient. Adding Langfuse infrastructure before we need it is overhead.

2. **Integration clarity**: By Phase 3, the `AgentChat.LLM` module is stable, and we know exactly what to instrument. Integrating Langfuse with a module that's still being refactored (Phase 1) would mean updating the integration as the code changes.

3. **Cost validation**: Starting with Langfuse Cloud (free tier) lets us validate the value before committing to self-hosted infrastructure. If the team doesn't look at the dashboards, we know not to invest in self-hosting.

### Q: Can we skip Langfuse Cloud and go directly to self-hosted?

Yes, but it's not recommended. Self-hosted Langfuse requires:

- Kubernetes cluster (or Docker Compose, but not HA)
- ClickHouse instance (the biggest operational burden)
- PostgreSQL instance (can reuse existing)
- Redis instance
- S3-compatible storage
- DevOps time for setup, maintenance, upgrades

The Cloud tier starts at **$0/month** (50k traces). For a team validating the tooling, the free tier eliminates all infrastructure overhead. Graduate to self-hosted when:

- Trace volume exceeds 5M/month (Cloud Pro at $199/mo starts to be expensive)
- Data residency requirements mandate on-premises
- The team is confident Langfuse is the right tool (validated on Cloud)

### Q: What about using OpenAI's built-in dashboard for observability?

OpenAI's dashboard shows API usage and costs, which is useful but limited:

1. **No tracing**: You can't see the full conversation lifecycle (prompt building → LLM call → tool execution → response)
2. **No evaluation**: No LLM-as-judge, no manual labeling, no regression testing
3. **No prompt management**: Prompts live in your code, not in OpenAI's platform
4. **Vendor lock-in**: If you switch to Anthropic or Google, you lose all observability
5. **No school-scoped views**: OpenAI shows aggregate usage, not per-school breakdowns

OpenAI's dashboard is a complement, not a replacement, for proper LLM observability.

---

## 8. Migration & Rollback

### Q: What's the rollback plan if the ReqLLM migration breaks something in production?

The migration is behind clean module boundaries. Rollback options:

1. **Git revert**: The changes are in 2 files (`agent_chat.ex`, `chat_response_worker.ex`) + 1 new module (`agent_chat/llm.ex`). Reverting to the LangChain version is a `git revert` of the migration commit.

2. **Feature flag**: We can introduce a temporary feature flag that switches between the old LangChain path and the new ReqLLM path. This is overkill for a 2-file change but available if the team wants it.

3. **LangChain stays in mix.exs until Phase 1 is verified**: We can keep `{:langchain, "0.4.0"}` in deps until we've verified the ReqLLM path in staging. Remove it only after confidence.

The key point: the database schema doesn't change in Phase 1. All messages, conversations, and model calls are stored in the same format. The migration is purely at the code layer — fully reversible.

### Q: How do we migrate the `strand_agent_conversations` data without downtime?

The migration is additive:

1. Deploy the `conversation_contexts` table (new table, no impact on existing)
2. Run a data migration that copies rows from `strand_agent_conversations` to `conversation_contexts`
3. Deploy code that reads from `conversation_contexts`
4. Old code that reads `strand_agent_conversations` continues to work (the data is still there)

There is no downtime because:
- Step 1 is a new table (zero impact)
- Step 2 is a background migration (can run during low-traffic hours)
- Step 3 deploys new code that reads the new table
- The old table is never dropped or modified

If the new code has a bug, we revert the deploy. The old code still reads the old table. No data loss.

### Q: What if a migration between phases fails? Can we run Phase 3 without Phase 2?

No. The phases are sequential dependencies:

- **Phase 1** (LLM abstraction) is required by all subsequent phases — they all use `AgentChat.LLM`
- **Phase 2** (context + rich messages) is required by Phase 3 — memory injection uses the context resolution pipeline
- **Phase 3** (memory) is independent of Phase 4 — streaming doesn't need memory
- **Phase 4** (streaming) is independent of Phase 5 — file uploads don't need streaming

So the dependency chain is: 1 → 2 → 3, and 1 → 4, and 1 → 5. Phase 3, 4, and 5 are independent of each other (after Phase 2 for 3, after Phase 1 for 4 and 5).

---

## 9. Testing

### Q: How do we test the `AgentChat.LLM` module without making real API calls?

The same pattern already used for ILP revisions — dependency injection:

```elixir
# Production: uses ReqLLM
AgentChat.LLM.run_completion(model, messages, tools)

# Test: inject stub module
AgentChat.LLM.run_completion(model, messages, tools, llm_module: Lanttern.ReqLLMStub)
```

The `ReqLLMStub` already exists in `test/support/stubs/req_llm.ex`. We extend it to handle tool calling:

```elixir
defmodule Lanttern.ReqLLMStub do
  def generate_text(_model, _context, opts \\ []) do
    case Keyword.get(opts, :stub_response, :text) do
      :text ->
        {:ok, %ReqLLM.Response{message: text_message("Stub response")}}
      :tool_call ->
        {:ok, %ReqLLM.Response{message: tool_call_message("create_lesson", %{...})}}
    end
  end
end
```

This lets us test the full pipeline (message building → LLM call → response extraction → tool execution) without real API calls.

### Q: How do we test streaming?

Streaming tests use a stub that emits chunks:

```elixir
defmodule Lanttern.ReqLLMStreamStub do
  def stream_text(_model, _context, callback, _opts \\ []) do
    callback.({:chunk, "Hello "})
    callback.({:chunk, "world"})
    callback.({:done, %{usage: %{input: 10, output: 5}}})
    :ok
  end
end
```

The test subscribes to PubSub, sends a message, and asserts that `:chunk` events arrive in order, followed by `:message_complete`.

### Q: How do we test the memory summarization? It calls the LLM.

The `MemorySummaryWorker` accepts an LLM module via dependency injection (same pattern). The test stub returns a predetermined summary:

```elixir
# Test
test "summarizes conversation into memory entries" do
  conversation = insert(:agent_conversation, ...)
  insert(:agent_message, conversation: conversation, role: "user", content: "I prefer hands-on activities")
  insert(:agent_message, conversation: conversation, role: "assistant", content: "Noted! I'll suggest...")

  perform_job(MemorySummaryWorker, %{conversation_id: conversation.id}, llm_module: SummaryStub)

  memories = AgentChat.Memory.list_user_memories(scope, profile)
  assert length(memories) == 1
  assert hd(memories).summary =~ "hands-on"
end
```

---

## 10. Performance & Cost

### Q: How much will this architecture cost in LLM API fees?

Cost depends on usage volume. Estimates for a school with 50 active teachers:

| Operation | Tokens/call | Calls/week | Cost/week (GPT-4o) | Cost/week (GPT-4o-mini) |
|---|---|---|---|---|
| Chat message (with context) | ~3,000 in + ~1,000 out | 500 | ~$5.00 | ~$0.15 |
| Memory summarization | ~2,000 in + ~200 out | 50 | ~$0.50 | ~$0.02 |
| Conversation rename | ~500 in + ~50 out | 50 | ~$0.05 | ~$0.002 |
| **Total** | | | **~$5.55/week** | **~$0.17/week** |

Using GPT-4o-mini for summarization and rename (non-user-facing) significantly reduces costs. The school's `base_model` controls the primary chat model.

Phase 4 adds **budget enforcement**: schools can set `monthly_token_budget` in `school_ai_configs`. The worker checks the budget before making an LLM call and returns an error if exceeded.

### Q: Will the memory injection increase token costs significantly?

Memory injection adds ~200-500 tokens per conversation (the summary layer). For a conversation with 3,000 tokens of context already (strand + lesson + school config), memories add ~10-15% overhead. This is negligible compared to the value of personalized responses.

The cap (top 10 memories) prevents unbounded growth. If a user has 100 memories, only the 10 most relevant are injected.

### Q: What's the performance impact of the polymorphic context table?

The `conversation_contexts` table has:
- A unique index on `(conversation_id, context_type, context_id)`
- An index on `(context_type, context_id)`

Loading contexts for a conversation is a single query:

```sql
SELECT * FROM conversation_contexts WHERE conversation_id = $1;
```

This returns 1-3 rows (strand, lesson, maybe ILP). The query hits the index directly. Performance is identical to the current `strand_agent_conversations` query — one indexed lookup returning a handful of rows.

---

## 11. Security & Data Ownership

### Q: If we adopt Langfuse Cloud, are we sending conversation data to a third party?

Yes. Langfuse Cloud receives traces, which can include prompt content, completion content, and token counts. However:

1. **GDPR compliant**: Langfuse offers EU data residency and a DPA (Data Processing Agreement)
2. **SOC 2 Type II certified**: Standard security compliance
3. **Data masking**: You can mask sensitive fields before sending traces
4. **Opt-in content**: You control what data is included in traces. You can send only metadata (model, tokens, latency) without actual message content.

For maximum data control, self-hosted Langfuse keeps everything on your infrastructure. The phased approach (Cloud → self-hosted) lets you start with convenience and move to control when needed.

### Q: How do we secure the SSE endpoint (Phase 5) for Vercel AI SDK?

The SSE endpoint needs separate security because it's not a LiveView route (no WebSocket, no CSRF token):

1. **Session authentication**: The React island shares the same browser session as the LiveView page. The SSE endpoint validates the session cookie.
2. **CSRF protection**: Use a CSRF token passed from LiveView to the React island as a prop. The React component includes it in the SSE request header.
3. **Rate limiting**: Apply per-user rate limiting middleware (plug) on the SSE endpoint.
4. **Scope authorization**: The endpoint checks `Scope.has_permission?(scope, "agents_management")` before processing.

```elixir
# router.ex
pipeline :api_auth do
  plug :fetch_session
  plug :verify_session_user
  plug :verify_csrf_header  # Custom plug: checks X-CSRF-Token header
  plug :rate_limit, max: 10, window: 60_000  # 10 requests/minute
end

scope "/api" do
  pipe_through [:api_auth]
  post "/chat", AiStreamController, :stream
end
```

### Q: What about data ownership with ReqLLM? Are API calls logged by providers?

When ReqLLM calls the OpenAI API, OpenAI processes the request per their API terms. Specifically:

1. **OpenAI does not train on API data** (as of their current policy)
2. **OpenAI retains API data for 30 days** for abuse monitoring (unless you opt out via their API data retention settings)
3. **Lanttern stores all conversation data** in its own database — we have a complete local copy

The same applies to any provider (Anthropic, Google, etc.). The architecture stores all data locally; the provider gets a copy during the API call. For maximum control, schools can configure local/private models (via ReqLLM's provider support) when they become available.

---

## 12. Timeline & Prioritization

### Q: Can we skip phases or do them in parallel?

**Parallel opportunities:**
- Phase 3 (Memory) and Phase 4 (Streaming) are independent after Phase 2. They can run in parallel if the team has capacity.
- Phase 5 (File uploads + React) is independent after Phase 1.

**Cannot be skipped:**
- Phase 1 (LLM abstraction) is foundational — everything depends on it
- Phase 2 (Context) is required by Phase 3 (Memory uses the context pipeline)

**Can be deferred:**
- Phase 4 (Streaming) — nice UX improvement but not blocking
- Phase 5 (React + File uploads) — depends on React setup progress

### Q: What if the React setup is ready before Phase 5? Can we bring it forward?

Yes. The React chat island (Phase 5, Steps 5.3-5.4) can be moved to Phase 4 or even Phase 3 if:

1. React islands infrastructure is working
2. The `AgentChat.LLM` abstraction is stable (Phase 1 complete)
3. The SSE endpoint can be built quickly (it's a thin translation layer over PubSub)

The backend doesn't change — only the frontend path is added. This is the benefit of the UI-agnostic architecture.

### Q: Is 2 weeks per phase realistic?

Each phase is scoped to a specific, bounded set of changes:

- **Phase 1**: 2 files rewritten + 1 new module + test updates. 2 weeks is comfortable.
- **Phase 2**: 1 migration + 1 new module + component changes. 2 weeks is tight but doable.
- **Phase 3**: 1 migration + 1 new module + 1 Oban worker + UI page. 2 weeks is tight. Could extend to 3.
- **Phase 4**: Streaming (new path in worker + component) + cost tracking. 2 weeks is tight. Could extend to 3.
- **Phase 5**: Multiple independent features. Expected to take 3-4 weeks.

The estimates are optimistic-but-achievable. Buffer should be added for integration testing and unexpected issues.

---

## 13. Vercel AI SDK Specifics

### Q: How does the Vercel Data Stream Protocol actually work?

It's an SSE (Server-Sent Events) protocol where each event is a single line with a type prefix:

```
0:"Hello "          → text chunk "Hello "
0:"world"           → text chunk "world"
9:{"toolCallId":"1","toolName":"create_lesson","args":{"description":"..."}}
a:{"toolCallId":"1","result":{"lesson_id":42}}
e:{"finishReason":"stop","usage":{"promptTokens":150,"completionTokens":50}}
d:{"finishReason":"stop"}
```

Type codes:
- `0` = text token
- `9` = tool call
- `a` = tool result
- `e` = finish with metadata
- `d` = done signal

The Phoenix controller needs to produce this exact format. It's a string concatenation exercise — not complex, just precise.

### Q: Does useChat work with non-streaming (batch) responses?

Yes. `useChat` also supports non-streaming responses. If the backend returns the complete message at once (instead of streaming), `useChat` still handles it correctly — it just appears all at once instead of token-by-token.

This means we can adopt the React island before implementing streaming. The SSE endpoint can return a single complete message (like our current batch flow), and `useChat` will display it.

### Q: What happens if the SSE connection drops mid-stream?

`useChat` handles reconnection automatically. When the connection drops:

1. The current partial message is preserved in the component state
2. The hook attempts to reconnect (configurable retry behavior)
3. If reconnection fails, the message is marked as incomplete

The backend handles this by checking if the Oban job already completed. If the worker finished and persisted the message, the reconnected client loads the complete message from the database (via an API call or LiveView bridge).

---

## 14. Langfuse Specifics

### Q: How does OpenTelemetry integration work with Elixir specifically?

The Elixir/BEAM ecosystem has strong OpenTelemetry support via the `opentelemetry` hex packages:

```elixir
# mix.exs
{:opentelemetry, "~> 1.4"},
{:opentelemetry_api, "~> 1.3"},
{:opentelemetry_exporter, "~> 1.7"}
```

Configuration to export to Langfuse:

```elixir
# config/runtime.exs
config :opentelemetry, :resource, service: %{name: "lanttern"}
config :opentelemetry,
  span_processor: :batch,
  exporter: {:opentelemetry_exporter, %{
    endpoints: ["https://your-langfuse.com/api/public/otel"],
    headers: [{"Authorization", "Bearer #{langfuse_api_key}"}]
  }}
```

Then in the code:

```elixir
require OpenTelemetry.Tracer, as: Tracer

def run_completion(model, messages, tools, opts) do
  Tracer.with_span "llm.completion" do
    Tracer.set_attributes([
      {"llm.model", model},
      {"llm.provider", "openai"},
      {"llm.messages_count", length(messages)}
    ])

    result = do_llm_call(model, messages, tools, opts)

    case result do
      {:ok, response} ->
        Tracer.set_attributes([
          {"llm.tokens.input", response.usage.input},
          {"llm.tokens.output", response.usage.output}
        ])
      _ -> :ok
    end

    result
  end
end
```

Langfuse's OTLP endpoint receives these spans and displays them in its trace viewer.

### Q: Can we use Langfuse for prompt management instead of keeping prompts in code?

Yes, but it's a Phase 5+ consideration. Langfuse's prompt management allows:

1. **Versioning**: Keep multiple versions of a prompt, deploy specific versions
2. **Playground**: Test prompts against different models directly in the Langfuse UI
3. **Caching**: Server-side + client-side caching to avoid loading prompts on every call
4. **Non-developer iteration**: Educators or product managers can tweak prompts without code changes

The trade-off is that prompts move from version-controlled code to an external service. This adds a runtime dependency (Langfuse must be available to load prompts) and reduces code-level visibility.

The recommendation is: keep prompts in code for now (Phase 1-3). Evaluate Langfuse prompt management in Phase 5 when the observability infrastructure is mature and the team has experience with the platform.

### Q: What about Langfuse's evaluation features? How would we use them?

Langfuse evaluation enables automated quality checks on AI outputs. Practical examples for Lanttern:

1. **LLM-as-judge**: After a lesson plan is generated, a separate LLM call evaluates it against rubrics (e.g., "Does the plan include differentiation?", "Is it age-appropriate?"). The score is stored in Langfuse.

2. **User feedback**: When a teacher marks a lesson plan as "helpful" or "not helpful", that feedback is sent to Langfuse as a score attached to the trace. Over time, this builds a dataset for measuring quality trends.

3. **Regression testing**: When prompts change, run the same set of test conversations through the new prompt and compare scores against the old prompt. This prevents quality regressions.

These are Phase 3+ features. They require the tracing infrastructure to be in place first.

---

## 15. Jido Ecosystem

### Q: You mentioned Jido could be reconsidered in the future. When specifically?

Jido becomes relevant when Lanttern needs:

1. **Multiple independent agents** that coordinate with each other (e.g., a "lesson planner" agent that delegates to a "curriculum researcher" agent and an "assessment designer" agent)
2. **Complex state machines** where the agent's behavior changes based on accumulated state (beyond what a database can represent efficiently)
3. **Real-time agent collaboration** where multiple agents work on the same task concurrently and need to share intermediate results

Currently, Lanttern has one agent type (lesson planner) with a simple lifecycle (receive message → think → respond/act). Oban handles this perfectly.

If the 2026 roadmap evolves toward multi-agent systems, revisit Jido at that point. The `AgentChat.LLM` abstraction makes this possible — Jido would replace the worker layer, not the LLM client layer.

### Q: What about `jido_action` for typed tools? That seems better than what we're proposing.

`jido_action` provides compile-time schema validation for tool definitions and automatic conversion to the LLM's tool format. It's genuinely better than hand-written tool specs.

However, Lanttern currently has exactly **2 tools** (create_lesson, update_lesson) with a third planned (set_conversation_title). The overhead of a framework for 3 tools is not justified.

When the tool count grows (10+), the compile-time validation and auto-conversion become valuable. At that point, `jido_action` can be adopted inside `AgentChat.Tools` without changing anything outside that module.

### Q: Is there a risk that the Jido ecosystem becomes the Elixir standard and we miss out?

Jido is promising but new (v2.0 released recently). The Elixir AI ecosystem doesn't have a "standard" yet — it's too early. By choosing ReqLLM (part of the Jido ecosystem) for the LLM client, we're already benefiting from the ecosystem's best component.

If Jido becomes the standard, adopting it later is straightforward because:
1. ReqLLM (already adopted) is the foundation of Jido's LLM layer
2. `AgentChat.LLM` abstracts the orchestration — replacing it with Jido's orchestration is a bounded change
3. The database schema, PubSub patterns, and UI layer are Jido-agnostic

We're making a pragmatic bet: adopt the proven parts (ReqLLM) and defer the unproven parts (Jido agents) until they're battle-tested and we need them.

---

## 16. Monolith vs Microservice

### Q: Let's be honest — doesn't Python have much better AI tools? Why are we limiting ourselves to Elixir?

Yes, Python's AI ecosystem is objectively richer. Here's what we're missing by staying in Elixir:

| Category | What Python has | What Elixir has | Gap severity |
|---|---|---|---|
| **Agent orchestration** | LangGraph (stateful, checkpointing, time-travel, 5 streaming modes) | Custom tool_call_loop (~25 lines) | **Large** |
| **Multi-agent** | CrewAI, AG2/AutoGen, Swarm | Nothing production-ready | **Large** |
| **RAG/Documents** | LlamaIndex (loaders, chunking, retrieval pipelines) | Manual implementation | **Large** |
| **Evaluation** | DeepEval, RAGAS, PromptFoo | Nothing | **Large** |
| **Structured output** | Instructor (3M+ downloads), Pydantic AI | Ecto validation (manual) | **Medium** |
| **Provider SDKs** | Official from OpenAI, Anthropic, Google | ReqLLM (community, good but not official) | **Small-Medium** |
| **Memory** | mem0, MemGPT/Letta | Custom implementation | **Medium** |
| **Observability** | Native Langfuse/LangSmith SDKs | OpenTelemetry (works, not native) | **Small-Medium** |

The gaps are real. The question is: **do we need these capabilities today, and is the cost of a microservice worth the access?**

For Lanttern's current needs (LLM client, tool calling, basic memory, streaming), Elixir + ReqLLM is sufficient. The gaps that matter most (LangGraph orchestration, DeepEval evaluation) are future needs, not blocking ones.

### Q: What would a Python sidecar architecture actually look like?

A co-deployed FastAPI service running alongside Phoenix, sharing the same PostgreSQL and Redis:

```
User prompt → Phoenix LiveView → POST http://localhost:8000/chat
                                        │
                                        ▼
                                  FastAPI (Python)
                                  │ 1. GET context from Phoenix
                                  │ 2. Run LangGraph agent
                                  │ 3. On tool call → POST to Phoenix internal API
                                  │ 4. On chunk → publish to Redis
                                  │ 5. On complete → POST message to Phoenix
                                        │
                                        ▼
                                  Redis (PubSub bridge)
                                        │
                                        ▼
                                  Phoenix PubSub → LiveView update
```

The sidecar handles LLM orchestration. Phoenix keeps all domain logic (Scope, Ecto, business rules, tool execution). Communication is localhost HTTP (~5-10ms overhead).

### Q: If we hire a Python AI engineer, how would they work with the Elixir codebase?

They wouldn't need to touch Elixir. The sidecar pattern creates a clean boundary:

- **Python engineer owns**: FastAPI service, LangGraph agents, evaluation pipelines, memory optimization, RAG if needed
- **Elixir team owns**: Phoenix, LiveView, business logic, Scope/auth, database, tool execution endpoints
- **Shared contract**: Internal HTTP API between the two services (documented, versioned)

The Python engineer deploys their service alongside Phoenix. They consume internal APIs that the Elixir team exposes. No cross-language code reviews needed.

### Q: How would tool calls (create_lesson) work across the service boundary?

When the LangGraph agent decides to call `create_lesson`, the flow is:

1. LangGraph emits a tool call: `{"name": "create_lesson", "args": {"description": "...", "moment_id": 1}}`
2. FastAPI receives the tool call and forwards it to Phoenix: `POST http://localhost:4000/internal/tools/create_lesson`
3. Phoenix receives the request, validates the scope token, calls `Lessons.create_lesson/3` with proper authorization and audit logging
4. Phoenix returns the result: `{"lesson_id": 42, "status": "ok"}`
5. FastAPI feeds the result back to LangGraph, which continues the conversation

The critical point: **Phoenix still owns tool execution**. The microservice never touches business logic directly. This preserves Scope authorization, audit logging, and data integrity.

### Q: What's the real latency impact?

| Architecture | Prompt-to-first-token | Tool call round-trip | Total for typical exchange |
|---|---|---|---|
| **Elixir monolith** | LLM API latency only (~500ms) | 0ms (in-process) | ~2-5 seconds |
| **Python sidecar** | +5-10ms (localhost hop) | +10-20ms (two localhost hops) | ~2-5.1 seconds |
| **Full microservice** | +25-50ms (network hop) | +50-100ms (two network hops) | ~2-5.3 seconds |

For a chat interface where the LLM API itself takes 2-5 seconds per response, the sidecar overhead (5-10ms) is imperceptible. The full microservice overhead (25-50ms) is noticeable only during streaming (choppy token delivery).

### Q: Wouldn't TypeScript be more natural since we're adding React anyway?

TypeScript has advantages for the frontend layer (Vercel AI SDK is native), but for the AI backend:

- TypeScript's AI ecosystem is a **subset of Python's**. LangChain.js and LangGraph.js exist but have smaller communities. CrewAI, LlamaIndex, DeepEval, RAGAS, Instructor — all Python-only.
- TypeScript's strength is frontend, not AI orchestration.
- If we're adding a service for AI orchestration, Python gives us access to 10x more tools.

If we hire an AI engineer, they will almost certainly know Python, not TypeScript. TypeScript is the right choice for the chat UI (React + Vercel AI SDK). Python is the right choice for AI orchestration (if we need a separate service).

### Q: What's the real operational cost of running two services?

| Dimension | Monolith | Sidecar | Full microservice |
|---|---|---|---|
| **Monthly infra** | ~$5K | ~$5.5-6.5K | ~$18-30K |
| **CI/CD pipelines** | 1 | 1 (co-deployed) | 2 (separate) |
| **On-call complexity** | Low | Low (same host) | Medium (cross-service debugging) |
| **Integration tests** | Standard | Need cross-service tests | Need contract tests + E2E |
| **Config management** | 1 set of env vars | 2 sets, shared secrets | 2 sets, network auth, service discovery |

The sidecar is the sweet spot: 90% of the Python ecosystem benefits with only 10% of the microservice operational cost. Same deployment unit, same host, shared database.

### Q: What if we need RAG for curriculum documents (PDFs, textbooks)?

This is one of the strongest arguments for a Python sidecar. LlamaIndex provides:

- **Document loaders**: PDF, DOCX, HTML, Google Docs — 100+ formats
- **Chunking strategies**: Semantic, sentence-based, recursive — optimized for education content
- **Embedding models**: OpenAI, Cohere, local models
- **Vector stores**: pgvector, Pinecone, Qdrant — first-class integrations
- **Retrieval pipelines**: Hybrid search, re-ranking, query transformation

Building equivalent functionality in Elixir would require writing custom document parsers, chunking algorithms, and vector search integrations — weeks of work that LlamaIndex provides out of the box.

If RAG over curriculum documents becomes a requirement, this alone justifies a Python sidecar.

### Q: Is LangGraph really that much better than our custom tool_call_loop?

For what Lanttern does today (simple request → tool call → response), our 25-line loop is fine. But LangGraph provides capabilities we can't easily replicate:

| Feature | Our tool_call_loop | LangGraph |
|---|---|---|
| Basic tool calling | Yes | Yes |
| Multi-turn tool calls | Yes (with max_iterations) | Yes (built-in) |
| **Checkpointing** | No | Yes — save/resume agent state at any point |
| **Time-travel debugging** | No | Yes — replay conversations from any checkpoint |
| **Human-in-the-loop** | No | Yes — pause agent, ask human, resume |
| **Parallel tool calls** | No | Yes — call multiple tools simultaneously |
| **Streaming modes** | 1 (token) | 5 (tokens, events, updates, messages, custom) |
| **Branching** | No | Yes — explore alternative conversation paths |
| **Durable execution** | Oban retries (coarse) | Fine-grained state recovery mid-conversation |

For a tutoring agent that needs to pause for teacher input, resume from a saved state, or explore different explanation strategies — LangGraph is far ahead. For a lesson planning chatbot, our loop suffices.

### Q: What does the industry data say about microservices for AI?

Key data points:

- **42% reversal**: A 2025 CNCF survey found 42% of organizations that adopted microservices have consolidated services back into larger units. Premature splitting is the most common mistake.
- **Amazon Prime Video**: Migrated their video quality analysis from microservices to a single-process monolith, achieving **90% infrastructure cost reduction**.
- **Vercel, Notion, Stripe**: Use AI gateways (translation layers) rather than full microservices. They keep AI orchestration close to the main application.
- **Modular monolith trend**: The industry is converging on modular monoliths with clean internal boundaries that CAN be extracted later — exactly what our `AgentChat.LLM` abstraction provides.

The pattern that works: **start monolith, extract only when you have a proven need** (scale, team independence, or ecosystem access). Don't extract preemptively.

### Q: What's the migration path from monolith to sidecar?

The `AgentChat.LLM` module is the extraction point. Today it wraps ReqLLM. Tomorrow it can wrap an HTTP call to a Python service:

```elixir
# Today (Phase 1): direct ReqLLM call
defp do_llm_call(model, messages, tools, opts) do
  ReqLLM.generate_text(model, context, tools: tools)
end

# Future (when sidecar adopted): HTTP call to FastAPI
defp do_llm_call(model, messages, tools, opts) do
  Req.post!("http://localhost:8000/chat", json: %{
    model: model,
    messages: messages,
    tools: tools,
    scope_token: opts[:scope_token]
  })
  |> parse_response()
end
```

Nothing outside `AgentChat.LLM` changes. The context module, workers, PubSub, UI — all unchanged. The extraction is one function body change in one module.

### Q: Should we start with a sidecar now instead of ReqLLM, to avoid migration later?

No. Reasons:

1. **You can't know what you need until you build it.** Using ReqLLM directly teaches us what the LLM abstraction needs. Premature extraction means building an API contract before understanding the requirements.
2. **The migration cost is tiny.** Changing one function body in `AgentChat.LLM` is a 30-minute task. Compare that to weeks of sidecar setup upfront.
3. **The sidecar adds operational complexity from day 1.** Two codebases, two test suites, a bridge layer — all before we know if we need it.

Build the monolith. Learn what the agent actually needs. Extract when a specific capability (LangGraph, DeepEval, RAG) demands it.

### Q: Can DeepEval / RAGAS evaluation be used without a microservice?

Partially. You have two options:

1. **Offline evaluation** (no microservice needed): Run DeepEval/RAGAS as a Python script that reads conversation data from the database, evaluates it, and writes results back. This is a batch process, not a runtime dependency. You can use CI/CD or a cron job.

2. **Runtime evaluation** (sidecar needed): If you want real-time evaluation (score every AI response before showing it to the user), the evaluation framework needs to be in the request path — which means a Python sidecar.

For Lanttern's current stage, **offline evaluation is sufficient**. Run a weekly batch that evaluates recent conversations for quality, safety, and relevance. This requires only a Python script, not a full sidecar.

---

## 17. CopilotKit vs Vercel AI SDK vs assistant-ui

### Q: What is the AG-UI Protocol and why does it matter?

AG-UI (Agent-User Interaction Protocol) is an open standard for agent-to-frontend communication, adopted by Google, AWS, LangChain, Microsoft, Mastra, and PydanticAI. It defines rich SSE event types (text streaming, tool calls, state snapshots, state deltas, lifecycle events, human approval) designed specifically for AI agents.

It matters because the Vercel Data Stream Protocol only supports text chunks and basic tool calls. AG-UI supports everything LangGraph can emit — state updates, multi-step workflows, human-in-the-loop approvals. When using LangGraph as a backend, AG-UI is a native fit while the Vercel protocol requires a lossy conversion.

### Q: Why would CopilotKit be better than Vercel AI SDK for Lanttern?

Three specific Lanttern features that CopilotKit handles natively and Vercel AI SDK does not:

1. **Teacher approval before lesson creation**: CopilotKit's human-in-the-loop pauses the agent, shows an approval UI, and resumes on teacher action. With Vercel AI SDK, you'd build this entirely from scratch.

2. **Agent status indicators** ("Loading strand context...", "Creating lesson...", "Waiting for approval..."): CopilotKit's STATE_DELTA events update the UI in real-time as the agent progresses through steps. Vercel AI SDK has no equivalent.

3. **Lesson card rendering**: Both support custom tool call renderers, but CopilotKit's generative UI system makes this more natural — the agent can dynamically decide what UI component to render.

### Q: When would Vercel AI SDK still be the right choice?

If Lanttern stays on the Elixir monolith (no Python sidecar), Vercel AI SDK is simpler:
- No LangGraph backend means AG-UI's rich events are irrelevant — the Elixir backend won't produce them
- Vercel AI SDK's `useChat` hook is lighter and easier to set up
- The community is 4x larger, meaning more examples and better documentation
- For basic chat with tool calls (current Lanttern feature set), Vercel AI SDK is sufficient

The rule: **Use CopilotKit if you have LangGraph. Use Vercel AI SDK if you don't.**

### Q: What about assistant-ui? When is it better than both?

assistant-ui is the choice when **visual customization matters more than agent features**. It's headless — no pre-built styles, you apply your own design system to every element.

For Lanttern specifically: if the team wants the chat UI to perfectly match Lanttern's existing design language (the amber AI theme, `ltrn-ai-*` Tailwind classes, custom components), assistant-ui gives more control. CopilotKit's pre-built components would need to be styled to match, which can fight the framework.

However, assistant-ui lacks state sync and human-in-the-loop — features Lanttern will likely need. The trade-off is: **maximum visual control** (assistant-ui) vs **maximum agent UX** (CopilotKit).

### Q: Can we switch between these later? How locked in are we?

Switching is moderate effort, not a rewrite:

- **CopilotKit → Vercel AI SDK**: Replace CopilotKit components with `useChat` hook + custom renderers. Backend SSE endpoint changes format (AG-UI → Data Stream Protocol). ~1-2 weeks.
- **Vercel AI SDK → CopilotKit**: Replace `useChat` with CopilotKit components. Backend changes SSE format. ~1-2 weeks.
- **Either → assistant-ui**: Replace components, adapt streaming adapter. ~1-2 weeks.

The backend architecture (`AgentChat.LLM`, `AgentChat.Tools`, Oban workers, PubSub) doesn't change in any scenario. The frontend choice is a UI-layer decision, not an architecture decision.

### Q: Does CopilotKit work with an Elixir/Phoenix backend?

Yes, but indirectly. CopilotKit consumes AG-UI events via SSE. Phoenix would need a controller that produces AG-UI-formatted SSE events. This is the same pattern as the Vercel AI SDK integration — a Phoenix controller that speaks the right protocol.

The difference: AG-UI events are richer (more event types to implement). If the Elixir backend doesn't produce state snapshots or human-in-the-loop events (because it's not LangGraph), CopilotKit still works but most of its advanced features go unused. That's why **CopilotKit + Elixir is not recommended** — you'd be using 30% of the framework.

### Q: How does the LangGraph → AG-UI → CopilotKit data flow work in practice?

Step by step for a user prompt:

1. User types in CopilotKit `<CopilotChat>` component
2. CopilotKit sends message to backend via AG-UI protocol (SSE POST)
3. FastAPI receives, creates LangGraph agent invocation
4. LangGraph runs the agent graph:
   - Emits `RUN_STARTED` → CopilotKit shows "thinking..." indicator
   - Emits `TEXT_MESSAGE_CONTENT` chunks → CopilotKit streams text token by token
   - Emits `TOOL_CALL_START` (create_lesson) → CopilotKit shows tool call UI
   - FastAPI calls Phoenix internal API to execute the tool
   - Emits `TOOL_CALL_END` with result → CopilotKit renders lesson card
   - Emits `STATE_DELTA` → CopilotKit updates status indicator
   - Emits `RUN_FINISHED` → CopilotKit shows final state
5. No conversion layer needed — AG-UI events map 1:1 to LangGraph events

### Q: Is AG-UI Protocol mature enough for production?

AG-UI was introduced in 2025 and has been adopted by Google, AWS, Microsoft, and LangChain. It's an open standard with a public spec (docs.ag-ui.com) and GitHub repo.

Risks:
- Newer than Vercel Data Stream Protocol (less battle-tested)
- CopilotKit is the primary implementor — if CopilotKit pivots, AG-UI's React ecosystem shrinks
- The spec may evolve (breaking changes in early standards)

Mitigations:
- Major corporate adoption (Google/AWS/MS) suggests stability
- Open standard means alternative implementations can emerge
- CopilotKit is open source — worst case, fork and maintain

For Lanttern's timeline (Phase 4-5, several months away), AG-UI will be more mature by the time we need it.
