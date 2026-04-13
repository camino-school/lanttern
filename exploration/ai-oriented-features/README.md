# AI-Oriented Features — Exploration Documents

Research and architecture planning for Lanttern's AI agent features (2026 roadmap).

## Documents

### Current State

| File | Purpose |
|------|---------|
| [how-is-ai-in-lanttern-today.md](how-is-ai-in-lanttern-today.md) | Technical reference of the current AI implementation. Documents both existing features (Agent Chat with LangChain, ILP AI Revision with ReqLLM), their architectures, database schemas, configuration hierarchy, and known gaps. |

### Architecture Plan

| File | Purpose |
|------|---------|
| [ai-agent-feature-plan.md](ai-agent-feature-plan.md) | Full architecture plan (English). Covers 8 architectural decisions (LLM client, orchestration, chat UI, streaming, memory, context, observability, monolith vs microservice), 4 deep dives (Vercel AI SDK, Langfuse, microservice ecosystems, frontend stack comparison), target architecture, database schema evolution, 5-phase implementation roadmap, and risk assessment. |
| [ai-agent-feature-plan-pt.md](ai-agent-feature-plan-pt.md) | Same architecture plan in Portuguese (PT-BR). |

### Q&A

| File | Purpose |
|------|---------|
| [ai-agent-feature-qa.md](ai-agent-feature-qa.md) | Anticipated developer questions (English). 17 sections covering every architectural decision with detailed answers — LLM client migration, orchestration trade-offs, frontend stack choices, streaming, memory, context, observability, migration/rollback, testing, performance/cost, security, timeline, Vercel AI SDK specifics, Langfuse specifics, Jido ecosystem, monolith vs microservice, and CopilotKit vs Vercel AI SDK vs assistant-ui. |
| [ai-agent-feature-qa-pt.md](ai-agent-feature-qa-pt.md) | Same Q&A document in Portuguese (PT-BR). |

## Reading Order

1. Start with **how-is-ai-in-lanttern-today.md** to understand the current implementation
2. Read **ai-agent-feature-plan.md** (or PT version) for the target architecture and decisions
3. Consult **ai-agent-feature-qa.md** (or PT version) for specific questions or trade-off details
