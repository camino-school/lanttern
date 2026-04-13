# Plano de Arquitetura dos AI Agents do Lanttern

> Documento de arquitetura técnica — Abril 2026
>
> Audiência: desenvolvedores, arquitetos e tomadores de decisão técnica trabalhando no roadmap de AI do Lanttern.
>
> Este documento é **opinionado** — apresenta todas as opções com prós/contras, mas faz recomendações claras com justificativas para cada decisão arquitetural.

---

## Sumário

1. [Contexto e Problema](#1-contexto-e-problema)
2. [Decisões Arquiteturais](#2-decisões-arquiteturais)
   - [Decisão 1: Camada de Client LLM](#decisão-1-camada-de-client-llm)
   - [Decisão 2: Orquestração de Agents](#decisão-2-orquestração-de-agents)
   - [Decisão 3: Chat UI e Frontend](#decisão-3-chat-ui-e-frontend)
   - [Decisão 4: Streaming](#decisão-4-streaming)
   - [Decisão 5: Memória do Usuário](#decisão-5-memória-do-usuário)
   - [Decisão 6: Contexto Universal de Conversas](#decisão-6-contexto-universal-de-conversas)
   - [Decisão 7: Observabilidade](#decisão-7-observabilidade)
   - [Decisão 8: Monolith vs Microservice](#decisão-8-monolith-vs-microservice)
3. [Deep Dive: Vercel AI SDK](#3-deep-dive-vercel-ai-sdk)
4. [Deep Dive: Langfuse](#4-deep-dive-langfuse)
5. [Deep Dive: Arquitetura Microservice e Ecossistemas Cross-Language](#5-deep-dive-arquitetura-microservice-e-ecossistemas-cross-language)
6. [Deep Dive: Escolhendo o Stack Frontend — CopilotKit + AG-UI vs Vercel AI SDK vs assistant-ui](#6-deep-dive-escolhendo-o-stack-frontend--copilotkit--ag-ui-vs-vercel-ai-sdk-vs-assistant-ui)
7. [Arquitetura Alvo](#7-arquitetura-alvo)
8. [Evolução do Schema do Banco de Dados](#8-evolução-do-schema-do-banco-de-dados)
9. [Roadmap de Implementação](#9-roadmap-de-implementação)
10. [Avaliação de Riscos](#10-avaliação-de-riscos)

---

## 1. Contexto e Problema

### O que temos hoje

O Lanttern atualmente possui **duas features de AI independentes** construídas em momentos diferentes com bibliotecas diferentes:

| Feature | Biblioteca | Propósito | Assíncrono? |
|---------|-----------|-----------|-------------|
| Agent Chat | LangChain 0.4.0 | Planejamento conversacional de aulas | Sim (Oban) |
| ILP AI Revision | ReqLLM ~> 1.6 | Revisão automatizada de ILPs | Não (síncrono) |

Ambas as features se comunicam exclusivamente com a **API da OpenAI**. Não há streaming — todas as respostas são geradas por completo antes da entrega.

### Por que precisamos refatorar agora

A implementação atual foi projetada como um **proof of concept (POC)**. Com AI agentic sendo a feature central do Lanttern em 2026, continuar iterando sobre a base do POC vai produzir uma bola de neve de dívida técnica. Os problemas específicos:

1. **Overhead de duas bibliotecas**: Manter duas bibliotecas LLM (LangChain + ReqLLM) dobra a carga cognitiva, superfície de dependências e complexidade de configuração.
2. **Sem streaming**: Os usuários esperam pela geração completa da resposta — UX inaceitável para interações mais longas.
3. **Sem memória entre conversas**: Cada conversa começa do zero. O agente não tem conhecimento de interações anteriores com o mesmo usuário.
4. **Contexto hardcoded**: A UI de conversa está amarrada a strands/lessons. A visão é um chat universal e context-aware.
5. **Resultados de tools em texto puro**: Quando a AI cria uma aula, ela escreve "A aula foi criada" em texto plano. Sem componentes de UI ricos.
6. **Sem controle de custos**: Dados de tokens são armazenados mas não utilizados. Sem orçamentos, sem limites, sem alertas.
7. **Sem observabilidade**: Além de contagem de tokens, não há tracing, avaliação ou infraestrutura de gerenciamento de prompts.
8. **Lock-in em único provedor**: Ambas as bibliotecas estão configuradas exclusivamente para OpenAI sem camada de abstração.

### Escopo deste documento

Este documento define a **arquitetura alvo** e um **roadmap de implementação faseado** para endereçar todos os pontos acima. Nem tudo será construído em um único sprint — o plano se distribui em 5 fases, cada uma de ~2 semanas.

---

## 2. Decisões Arquiteturais

### Decisão 1: Camada de Client LLM

**Pergunta**: Qual biblioteca o Lanttern deve usar para interagir com APIs de LLMs?

#### Opções

| Dimensão | Opção A: Status quo (LangChain + ReqLLM) | Opção B: Consolidar em ReqLLM | Opção C: Stack completa Jido |
|---|---|---|---|
| **Custo de migração** | Zero | Moderado (2 arquivos, ~25 pontos de chamada) | Alto (novo framework, novos paradigmas) |
| **Multi-provider** | Ambas suportam em teoria; código hardcoda `ChatOpenAI` | 10+ provedores nativos (OpenAI, Anthropic, Google, Mistral, Groq, AWS Bedrock...) | Mesmo que ReqLLM (jido_ai wraps req_llm) |
| **Streaming** | LangChain suporta, não utilizado atualmente | `stream_text/3` com suporte nativo a SSE | Mesmo que ReqLLM |
| **Tool calling** | LangChain `Function`/`FunctionParam` — verboso | `ReqLLM.Tool` — API mais simples | `jido_action` — actions tipadas com validação em tempo de compilação, auto-conversão para tools de LLM |
| **Carga cognitiva** | Duas APIs, duas abstrações, duas configs | Uma API, uma abstração, uma config | Um ecossistema, mas grande superfície (jido + jido_ai + jido_action + jido_signal) |
| **Testes** | LangChain usa Mimic; ReqLLM usa injeção de dependência | Padrão unificado de stub (já temos `ReqLLMStub`) | Novos padrões de teste necessários |
| **Idiomático Elixir** | LangChain é uma porta, não design nativo Elixir | Nativo Elixir, construído sobre Req | Nativo Elixir |
| **Maturidade** | LangChain 0.4.0 (cadência de updates incerta) | v1.0+ estável, production-ready | Jido v2.0 (novo, comunidade menor) |
| **Orquestração incluída?** | Sim (LLMChain com `while_needs_response`) | Não — você constrói o loop de tool-call | Sim (estratégias ReAct, Chain-of-Thought, CoD) |

#### Recomendação: **Opção B — Consolidar em ReqLLM**

**Justificativa:**

1. A superfície de acoplamento com LangChain é pequena e delimitada — exatamente 2 arquivos (`agent_chat.ex` e `chat_response_worker.ex`) com ~25 pontos de chamada. A migração é previsível.
2. ReqLLM já está no projeto, já testado, e seu padrão de stub (`Lanttern.ReqLLMStub`) está estabelecido.
3. ReqLLM é uma biblioteca focada (client LLM, não framework) — faz uma coisa bem e deixa a orquestração para a aplicação. Isso combina com a filosofia do Lanttern de ser dono da lógica de negócio.
4. O loop de tool-calling `while_needs_response` que o LangChain fornece equivale a **20-30 linhas de código Elixir customizado** — não é motivo para manter uma dependência de framework inteira.
5. Jido (Opção C) adiciona muita superfície de framework para o tamanho atual do time. Introduz novos conceitos (directives, signals, state machines de agentes) que não são necessários para os casos de uso atuais. Pode ser reconsiderado quando a complexidade dos agentes justificar (múltiplos agentes independentes, comunicação agent-to-agent, state machines complexas).
6. Consolidar em uma biblioteca corta pela metade a superfície de dependências, simplifica testes e remove a configuração do LangChain de `config.exs` e `runtime.exs`.

**O que perdemos do LangChain e como substituir:**

| Feature LangChain | Substituição no ReqLLM |
|---|---|
| `LLMChain` com `while_needs_response` | Função customizada `tool_call_loop/3` (~25 linhas) |
| `ChatOpenAI.new!` | `ReqLLM.generate_text/3` com config de provider |
| `Function` / `FunctionParam` | Definições `ReqLLM.Tool` |
| `Message.new_user!` / `new_assistant!` / `new_system!` | `ReqLLM.Context.user/1` / `ReqLLM.Context.assistant/1` / `ReqLLM.Context.system/1` |
| `ContentPart.content_to_string/1` | `ReqLLM.Response.text/1` |
| Token metadata de `chain.exchanged_messages` | Campos de usage do `ReqLLM.Response` |

#### Perspectiva cross-language: Como seria em Python ou TypeScript?

| Dimensão | Elixir (ReqLLM) | Python | TypeScript |
|---|---|---|---|
| **LLM Client** | ReqLLM (comunidade, 10+ providers) | OpenAI SDK / Anthropic SDK (first-class, oficiais, feature-complete) | OpenAI SDK / Anthropic SDK (equivalente ao Python) |
| **Tool calling** | `ReqLLM.Tool` — definições manuais | `Instructor` (3M+ downloads, schema-first) ou `Pydantic AI` (tipado, auto-validado) | Vercel AI SDK `tool()` ou validação com schema `zod` |
| **Structured output** | Validação com Ecto schema (manual) | `Instructor` ou `Pydantic AI` — outputs LLM estruturados automáticos com retries | `zod` + Vercel AI SDK `generateObject()` |
| **Maturidade** | ReqLLM v1.0 (estável, comunidade pequena) | OpenAI SDK v1.x (comunidade massiva, suporte oficial, milhões de usuários) | OpenAI SDK (features equivalentes, tipos via Zod) |
| **Multi-provider** | Nativo (10+ via ReqLLM) | Nativo (cada provider tem SDK oficial) + LiteLLM como wrapper unificado | Nativo + Vercel AI SDK abstrai providers |

**Veredito**: Python e TypeScript têm **ferramental de LLM client significativamente melhor** — SDKs oficiais, validação automática de structured output e comunidades maiores. ReqLLM é adequado mas requer mais código customizado. Essa lacuna é real mas gerenciável dentro do `AgentChat.LLM` — a abstração a isola.

---

### Decisão 2: Orquestração de Agents

**Pergunta**: Como o Lanttern deve orquestrar a execução dos AI agents (gerenciamento de jobs, retries, lifecycle)?

#### Opções

| Dimensão | Opção A: Baseado em Oban (atual, aprimorado) | Opção B: Agents GenServer (estilo Jido) | Opção C: Híbrido (Oban + Task.Supervisor) |
|---|---|---|---|
| **Funciona hoje** | Sim, comprovado em produção | Não — nova arquitetura | Parcialmente |
| **Suporte a streaming** | Necessita path paralelo (Task) | Encaixe natural (GenServer envia mensagens incrementais) | Task.Supervisor cuida do path de streaming |
| **Confiabilidade** | Retries nativos, dead-letter, constraints de unicidade | Precisa construir crash recovery, supervision | Oban para confiabilidade; Tasks para streaming |
| **Observabilidade** | Dashboard Oban Web já existe | Precisa construir customizado | Oban Web para jobs; telemetry para tasks |
| **Tratamento de falhas** | Retry automático com backoff | Restart do GenServer via supervisor | Split: retries do Oban para batch; falhas de tasks para streaming |
| **Testabilidade** | `testing: :manual` — jobs não executam automaticamente | Padrões de teste GenServer | Dois padrões de teste para manter |
| **Integração com memória** | Worker consulta memória antes de construir prompts | Agent mantém estado da conversa em memória | Mesmo que Opção A |
| **Complexidade** | Baixa — workers são apenas módulos | Alta — supervision tree, gestão de estado, deploy | Moderada — dois paths de execução |

#### Recomendação: **Opção A — Continuar baseado em Oban, com extensão de streaming (Opção C) quando streaming for adicionado**

**Justificativa:**

1. **Oban funciona.** Fornece retries, constraints de unicidade, pruning, observabilidade (via Oban Web), e isolamento de testes (`testing: :manual`). Substituí-lo seria trocar algo que não está quebrado.
2. Adicionar streaming depois não requer substituir Oban — significa adicionar um path paralelo usando `Task.Supervisor` para o caso de streaming. O worker pode escolher entre stream ou batch baseado na configuração.
3. Agents GenServer (Opção B) adicionam complexidade operacional que um time pequeno deve evitar, a menos que haja necessidade clara de estado in-memory. Atualmente, todo o estado está no banco de dados — não há necessidade de state machines in-memory.
4. Se Jido agents forem necessários no futuro (ex: coordenação multi-agent), eles podem coexistir com Oban. Não é uma decisão excludente.

#### Perspectiva cross-language: Como seria em Python ou TypeScript?

| Dimensão | Elixir (Oban) | Python | TypeScript |
|---|---|---|---|
| **Framework de agents** | Custom tool_call_loop (~25 linhas) | **LangGraph** — agents stateful com checkpointing, time-travel debugging, human-in-the-loop, 5 modos de streaming. Padrão da indústria. | **LangGraph.js** — mesmas features, comunidade menor (42k downloads npm semanais vs dominância do Python) |
| **Multi-agent** | Nada production-ready | **CrewAI** (times de agents baseados em papéis), **AG2/AutoGen** (multi-agent complexo), **Swarm** (lightweight) | LangGraph.js multi-agent, Mastra (emergente) |
| **Background jobs** | Oban (comprovado, retries, dashboard, backed por Postgres) | **Celery + Redis** (maduro, durável) ou **LangGraph** durable execution | **BullMQ** (911-8.300 jobs/sec, backed por Redis) |
| **Gestão de estado** | Banco de dados (PostgreSQL) | LangGraph checkpointing (in-memory ou persistente) — pause/resume/time-travel | LangGraph.js checkpointing |
| **Tolerância a falhas** | Oban retries + supervisors BEAM | Celery retries + LangGraph checkpoint recovery | BullMQ retries |

**Veredito**: A lacuna de orquestração é a **maior lacuna** entre Elixir e Python. LangGraph fornece execução stateful de agents, checkpointing, human-in-the-loop e coordenação multi-agent — nada disso existe em Elixir. Para as necessidades atuais do Lanttern (agents simples request-response), Oban é suficiente. Mas se agents se tornarem stateful (sessões de tutoria, workflows multi-step), as vantagens do LangGraph se tornam convincentes. Esta é a principal razão para considerar um sidecar Python no futuro.

---

### Decisão 3: Chat UI e Frontend

**Pergunta**: Qual tecnologia deve alimentar a interface de usuário do chat de AI?

#### Opções

| Dimensão | Opção A: LiveView Aprimorado | Opção B: React island + Vercel AI SDK | Opção C: React island + assistant-ui | Opção D: CopilotKit |
|---|---|---|---|---|
| **Custo de migração** | Zero | Alto (setup React + endpoint SSE + hook bridge) | Alto (setup React + protocolo custom) | Muito alto (adoção de plataforma completa) |
| **Streaming UX** | LiveView streams + PubSub push token-by-token | Hook `useChat` gerencia nativamente | Hook de streaming custom | Streaming nativo |
| **Componentes ricos** | Function components no message stream (cards de aula, etc.) | Componentes React para resultados de tool call — total flexibilidade | Mesmo que Vercel | Mesmo porém mais opinionado |
| **Familiaridade do time** | Alta — time inteiro conhece LiveView | Baixa — setup React em progresso, time aprendendo | Baixa | Baixa |
| **Auto-scroll, reconnect, abort** | Precisa construir manualmente | `useChat` fornece tudo isso | Parcialmente fornecido | Totalmente fornecido |
| **Complexidade de build** | Nenhuma | Compilação JSX do esbuild ou Vite para subtree React | Mesmo que Vercel | Mesmo + SDK da plataforma |
| **Footprint de dependências** | Nenhum | Pacote npm `ai` (~40KB) + React | `@assistant-ui/react` + React | `@copilotkit/react-*` + SDK backend |
| **Acoplamento backend** | Socket LiveView | Endpoint SSE (Vercel Data Stream Protocol) — separado do LiveView | Protocolo custom | Protocolo CopilotKit |
| **Model agnostic** | Sim (backend escolhe modelo) | Sim (backend faz stream, SDK é model-agnostic) | Sim | Sim |
| **Adoção da comunidade** | Comunidade Phoenix | Padrão da indústria para AI chat | Crescente, mais nova | Grande, foco enterprise |

#### Recomendação: **Opção A (LiveView Aprimorado) agora; transição para Opção B (Vercel AI SDK) quando setup React estiver pronto**

**Justificativa:**

1. **Pragmatismo imediato**: A integração React está em progresso mas não está pronta. Bloquear o trabalho de arquitetura AI em um setup React atrasaria o deliverable. LiveView consegue entregar tudo necessário para o v0: exibição de mensagens, estados de loading, e até streaming via PubSub.

2. **LiveView lida com componentes ricos nativamente**: Quando a AI cria uma aula, o `ConversationComponent` pode renderizar um `<.lesson_card>` function component inline no message stream. Isso requer zero React. A extensão do schema de mensagem (Phase 2) habilita isso: armazenar `ui_component: "lesson_card"` e `ui_data: %{lesson_id: 123}` no metadata da mensagem, então fazer pattern-match no template.

3. **O Vercel AI SDK é a escolha correta a longo prazo**: Quando React islands estiverem disponíveis, o hook `useChat` fornece gerenciamento de streaming, auto-scroll, updates otimistas, abort handling, e rendering de tool call — tudo que seria um esforço significativo para construir em LiveView. O caminho de transição é limpo porque o contrato do backend (`AgentChat` context, Oban workers, PubSub) é UI-agnostic.

4. **Evitar CopilotKit**: Seu SDK backend conflita com a arquitetura Elixir-centric do Lanttern. assistant-ui é uma alternativa viável ao Vercel AI SDK mas tem comunidade menor e menos documentação de integração para backends não-Next.js.

**Plano de transição**:
- Fases 1-3: Usar LiveView para UI do chat. Construir toda infraestrutura backend (abstração LLM, contexto, memória) sem acoplar a nenhum framework frontend.
- Fases 4-5: Quando React islands estiverem prontas, criar um React island de chat usando Vercel AI SDK. Adicionar um endpoint SSE no Phoenix que fala o Vercel Data Stream Protocol. Ambos os paths LiveView e React podem coexistir durante a transição.

#### Perspectiva cross-language

A decisão de Chat UI é majoritariamente **language-agnostic no backend** — o frontend é React independente da linguagem. Porém, com um backend TypeScript, o Vercel AI SDK seria **nativo** (sem bridge SSE necessário — o backend produz o stream diretamente). Com um backend Python (FastAPI), streaming SSE também é nativo (`StreamingResponse`). Com Elixir, precisamos de um controller Phoenix customizado para produzir o protocolo Vercel — factível mas mais trabalho manual.

**Veredito**: TypeScript tem uma leve vantagem para integração de Chat UI (Vercel AI SDK nativo). Python e Elixir são equivalentes (ambos precisam de um endpoint SSE). Isso não justifica uma mudança de linguagem já que a camada de UI é uma tradução fina.

---

### Decisão 4: Streaming

**Pergunta**: Como o Lanttern deve entregar respostas de AI ao usuário em tempo real?

#### Opções

| Dimensão | Opção A: Sem streaming (atual) | Opção B: Streaming via LiveView PubSub | Opção C: Endpoint SSE (Vercel Data Stream Protocol) |
|---|---|---|---|
| **UX** | Usuário espera pela resposta completa (pode ser 10-30 segundos) | Tokens aparecem conforme são gerados | Mesmo que B |
| **Implementação** | Nada a fazer | Worker/Task chama ReqLLM com streaming; faz broadcast de chunks via PubSub; ConversationComponent appenda chunks | Controller Phoenix retorna `text/event-stream`; `useChat` do Vercel AI SDK consome |
| **Mudanças no backend** | Nenhuma | `AgentChat.LLM` precisa de path de streaming; eventos PubSub para chunks | Novo controller + handler de response SSE |
| **Mudanças no frontend** | Nenhuma | ConversationComponent precisa de buffer de chunks + animação | React island com hook `useChat` |
| **Tool calls durante stream** | N/A | Worker pausa stream, executa tool, retoma | Vercel SDK lida via tipo de evento `9:` |
| **Funciona com LiveView** | Sim | Sim | Não (requer React) |
| **Funciona com React** | Sim (mas UX ruim) | Não (React não recebe PubSub) | Sim (projetado para isso) |

#### Recomendação: **Opção B para Phase 2 (streaming LiveView); adicionar Opção C na Phase 5 quando React estiver pronto**

**Justificativa:**

1. **Streaming é uma melhoria de UX, não um bloqueador de arquitetura.** Phase 1 deve focar em consolidação de bibliotecas e abstração. Streaming pode vir depois que a fundação estiver sólida.

2. **Opção B mantém tudo dentro do paradigma LiveView** — sem endpoint de API separado, sem handling adicional de auth/CSRF, sem dependência de React. Usa a infraestrutura PubSub existente que já conecta o Oban worker ao LiveView.

3. **O protocolo de streaming é aditivo**: Quando React estiver pronto (Phase 5), Opção C (endpoint SSE) é adicionada junto com Opção B, não substituindo. O backend pode suportar ambos os paths simultaneamente — o Oban worker produz chunks, que são entregues via PubSub (para LiveView) ou SSE (para React).

**Design do streaming PubSub:**

```
Novos eventos PubSub:
  {:conversation, {:chunk, %{text: "texto parcial", index: 0}}}
  {:conversation, {:tool_call_start, %{name: "create_lesson", args: %{...}}}}
  {:conversation, {:tool_call_result, %{name: "create_lesson", result: %{...}}}}
  {:conversation, {:message_complete, %Message{}}}

ConversationComponent:
  - Mantém assign `streaming_buffer` (acumula chunks)
  - Em `:chunk` → appenda ao buffer, re-renderiza mensagem em streaming
  - Em `:message_complete` → finaliza buffer na entrada do stream, salva no DB
```

#### Perspectiva cross-language

| Dimensão | Elixir (PubSub) | Python (FastAPI) | TypeScript (Node.js) |
|---|---|---|---|
| **Streaming para o client** | PubSub → LiveView push (customizado) | `StreamingResponse` (SSE nativo) | Vercel AI SDK `streamText()` (nativo, zero config) |
| **Streaming LangGraph** | N/A | **5 modos de streaming**: tokens, events, updates, messages, custom. O streaming mais avançado de qualquer framework. | LangGraph.js — mesmos 5 modos |
| **Tool calls durante stream** | Lógica manual de pause/resume | LangGraph lida automaticamente com `astream_events` | LangGraph.js ou Vercel AI SDK tipo de evento `9:` |
| **Reconexão** | Customizado (precisa construir) | Customizado (precisa construir) | Vercel AI SDK `useChat` lida automaticamente |

**Veredito**: Python (LangGraph) tem as **melhores capacidades de streaming** — 5 modos distintos que cobrem todo caso de uso (streaming de tokens, updates de estado, eventos de tool call, dados customizados). TypeScript (Vercel AI SDK) tem a melhor integração de streaming no frontend. A abordagem PubSub do Elixir funciona mas requer mais código customizado para cenários avançados. Para streaming simples de tokens, os três são adequados.

---

### Decisão 5: Memória do Usuário

**Pergunta**: Como o agente deve lembrar de informações entre conversas?

#### Abordagem de design: **Memória baseada em resumos hierárquicos**

**Por que não replay de histórico bruto?** Armazenar e reproduzir histórico bruto de conversas como "memória" é proibitivo em custo. Um usuário com 50 conversas de 20 mensagens cada exigiria injetar ~1000 mensagens em cada novo prompt — estourando a janela de contexto e o orçamento de tokens.

**Por que resumos?** No encerramento da conversa (ou em checkpoints), um job em background resume a conversa em entradas de memória compactas. Esses resumos são injetados como mensagem de sistema Layer 0 (antes da configuração da escola) em conversas futuras — adicionando ~200-500 tokens de contexto ao invés de milhares.

#### Design do schema

```
user_ai_memories
  id              :bigint PK
  profile_id      :bigint FK -> profiles (indexado)
  school_id       :bigint FK -> schools (indexado)
  category        :string  -- "preference" | "topic_expertise" | "interaction_style" | "context"
  summary         :text    -- texto de memória comprimido
  source_type     :string  -- "conversation" | "system" | "manual"
  source_id       :bigint  -- nullable, FK para conversa que produziu esta memória
  relevance_score :float   -- para ranking na recuperação (0.0-1.0)
  expires_at      :utc_datetime -- nullable, para memórias com tempo limitado
  inserted_at     :utc_datetime
  updated_at      :utc_datetime
```

#### Ciclo de vida da memória

1. **Criação**: Após o fim de uma conversa (ou em checkpoints periódicos), um job Oban `MemorySummaryWorker` resume a conversa e faz upsert de entradas de memória.
2. **Injeção**: Antes de construir system prompts, `add_memory_system_messages/2` consulta as memórias recentes/relevantes do usuário e as injeta como Layer 0 (antes de knowledge/guardrails da escola). Memórias são ordenadas por `relevance_score` e limitadas (ex: top 10 entradas) para controlar tamanho do prompt.
3. **Decay**: Memórias têm `expires_at` opcional para informações com tempo limitado. Um cron job faz prune de entradas expiradas.
4. **Atualização**: O job de sumarização pode atualizar memórias existentes (ex: "usuário prefere planos de aula detalhados" é refinado ao longo do tempo) em vez de sempre criar novas.
5. **Gestão manual**: Staff pode visualizar e deletar suas próprias memórias via página de configurações.

#### System prompt com memória (hierarquia de 6 camadas)

```
Layer 0: Memória do Usuário (NOVO)
  └── Fonte: tabela user_ai_memories
  └── Tag: <user_memory>
            <preferences>...</preferences>
            <topic_expertise>...</topic_expertise>
            <interaction_history>...</interaction_history>
          </user_memory>

Layer 1: Knowledge & Guardrails da Escola (inalterado)
Layer 2: Configuração do Agent (inalterado)
Layer 3: Contexto do Staff Member (inalterado)
Layer 4: Template de Aula (inalterado)
Layer 5: Contexto Curricular (inalterado)
```

Memória é posicionada antes da configuração da escola porque muda mais frequentemente (por-usuário, por-conversa), enquanto configuração da escola é relativamente estática. Esta ordenação maximiza a efetividade do prompt caching — as camadas estáticas permanecem na mesma posição entre chamadas.

#### Perspectiva cross-language

| Dimensão | Elixir (customizado) | Python | TypeScript |
|---|---|---|---|
| **Sistema de memória** | Tabela customizada `user_ai_memories` + job de sumarização | **mem0** (camada de memória gerenciada, auto-categoriza, vector search), **MemGPT/Letta** (memória auto-editável, storage em camadas), **LangGraph checkpointing** (persistência de estado de conversa com time-travel) | LangGraph.js checkpointing, implementações customizadas |
| **Vector search para memórias** | pgvector (funciona, integração manual) | Módulos de memória do **LlamaIndex**, pgvector, Pinecone, Qdrant — todos com integrações first-class | pgvector, Pinecone — similar ao Python |
| **Sumarização** | Job Oban customizado + chamada LLM | mem0 lida automaticamente, ou `summarize_messages` built-in do LangGraph | Customizado ou LangGraph.js |

**Veredito**: Python tem **sistemas de memória especializados** (mem0, MemGPT/Letta) que não existem em Elixir. Porém, estes são mais valiosos para agents complexos com longos históricos de interação. Nossa memória customizada baseada em resumos é mais simples e mais adequada às necessidades school-scoped do Lanttern. Se os requisitos de memória crescerem significativamente (ex: retrieval semântico baseado em vetores sobre milhares de conversas), o ecossistema Python se torna mais atrativo.

---

### Decisão 6: Contexto Universal de Conversas

**Pergunta**: Como conversas devem ser vinculadas a entidades arbitrárias (strands, lessons, ILPs, assessments, etc.)?

#### Limitação atual

A tabela `strand_agent_conversations` é hardcoded para strands e lessons:

```sql
strand_agent_conversations
  conversation_id → agent_conversations
  strand_id → strands
  lesson_id → lessons (nullable)
```

Isso não acomoda novos tipos de contexto (ILPs, assessments, students, etc.) sem novas tabelas de junção para cada tipo de entidade.

#### Recomendação: **Tabela polimórfica de context links**

```sql
conversation_contexts
  id                :bigint PK
  conversation_id   :bigint FK -> agent_conversations (CASCADE DELETE)
  context_type      :string  -- "strand" | "lesson" | "ilp" | "assessment" | ...
  context_id        :bigint  -- FK para a entidade relevante
  context_metadata  :jsonb   -- snapshot dos dados de contexto no momento da conversa
  inserted_at       :utc_datetime

  UNIQUE(conversation_id, context_type, context_id)
```

#### Decisões-chave de design

1. **Múltiplos contextos por conversa**: Uma conversa sobre uma aula dentro de um strand tem dois context links: `{type: "strand", id: 1}` e `{type: "lesson", id: 5}`. Isso é mais flexível do que forçar um único contexto.

2. **context_metadata JSONB**: Armazena um snapshot dos dados de contexto relevantes no momento da criação da conversa. Isso é útil para auditoria (o que o agente viu?) e para casos onde a entidade fonte muda após a conversa.

3. **Sem FK constraint em context_id**: Porque `context_id` pode referenciar diferentes tabelas dependendo do `context_type`, não podemos usar uma foreign key de banco de dados. A integridade referencial é garantida na camada de aplicação via `ContextResolver`.

4. **Caminho de migração**: Dados de `strand_agent_conversations` são migrados para `conversation_contexts` (uma linha por strand, uma por lesson onde aplicável). A tabela antiga permanece como está, conforme regra 7 do CLAUDE.md (padrão é dívida técnica, não refatoração).

#### Pipeline de resolução de contexto

```elixir
# Em AgentChat.ContextResolver
def resolve_contexts(conversation_id) do
  conversation_id
  |> list_conversation_contexts()
  |> Enum.flat_map(&context_to_system_messages/1)
end

defp context_to_system_messages(%{context_type: "strand", context_id: id}) do
  # Carrega strand com subjects, years, moments, curriculum items
  # Constrói system messages XML <strand_context>
end

defp context_to_system_messages(%{context_type: "lesson", context_id: id}) do
  # Carrega lesson com moment, subjects, tags
  # Constrói system messages XML <lesson_context>
end

defp context_to_system_messages(%{context_type: "ilp", context_id: id}) do
  # Carrega ILP com template, sections, entries
  # Constrói system messages XML <ilp_context>
end
```

Adicionar um novo tipo de contexto requer apenas adicionar uma nova cláusula `context_to_system_messages/1` — sem mudanças de schema, sem migrations.

#### Perspectiva cross-language

A resolução de contexto é **profundamente acoplada ao domínio do Lanttern** — carregar strands, lessons, ILPs requer queries em Ecto schemas com associações preloaded, enforcement de autorização via Scope e respeito ao isolamento por escola. Esta é a decisão **mais afetada pela escolha monolith vs microservice**.

| Cenário | Monolith Elixir | Microservice Python/TS |
|---|---|---|
| **Carregando contexto** | Query Ecto direta com preloads — 1 chamada ao DB, ~5ms | Microservice chama API interna do Phoenix → Phoenix faz query no DB → serializa → retorna JSON. Múltiplos hops, ~50-100ms. |
| **Novo tipo de contexto** | Adicionar uma cláusula de função no ContextResolver | Adicionar endpoint de API no Phoenix + código client em Python/TS + mapeamento de serialização |
| **Autorização** | Pattern-match de `school_id` no function head (Scope nativo) | Precisa passar token de Scope para o microservice ou duplicar lógica de auth |
| **Freshness dos dados** | Sempre ao vivo do DB | Risco de dados stale se caching, ou latência extra se sempre buscando |

**Veredito**: Resolução de contexto é o **argumento mais forte para manter AI no monolith Elixir**. Movê-la para um microservice não a simplifica — adiciona uma fronteira de rede no ponto de acoplamento mais apertado. Um microservice Python/TS precisaria ou acessar o banco do Lanttern diretamente (acoplamento forte, schema compartilhado, coordenação de migrations) ou chamar APIs internas para cada lookup de contexto (latência, complexidade).

---

### Decisão 7: Observabilidade

**Pergunta**: Como o Lanttern deve monitorar, avaliar e gerenciar qualidade e custos dos AI agents?

#### Opções

| Dimensão | Opção A: Custom (DB + Telemetry) | Opção B: Langfuse (self-hosted) | Opção C: Langfuse Cloud | Opção D: LangSmith | Opção E: Helicone |
|---|---|---|---|---|---|
| **Propriedade dos dados** | Total | Total (sua infraestrutura) | Gerenciado pela Langfuse (regiões EU/US, GDPR compliant) | Gerenciado pela LangChain | Gerenciado pela Helicone |
| **Custo** | Apenas storage no DB | Software gratuito + infra ($500-5k/mês) | Gratuito até $199+/mês | $39/seat/mês | Baseado em uso |
| **Esforço de setup** | Precisa construir tudo | Docker Compose (dev) ou K8s/Helm (prod) | Signup SaaS | Signup SaaS | Setup de proxy |
| **Tracing** | Manual (log no DB) | Tracing distribuído, hierarquia de spans, sessions | Mesmo | Mesmo | Auto-trace baseado em proxy |
| **Gestão de prompts** | Nenhuma (prompts no código) | Versionamento, caching, playground | Mesmo | Sim | Não |
| **Avaliação** | Nenhuma | LLM-as-judge, labeling manual, datasets | Mesmo | Sim | Não |
| **Tracking de custos** | Agregar de `llm_calls` | Por-modelo, por-usuário, por-session | Mesmo | Sim | Sim (feature principal) |
| **Integração Elixir** | Telemetry nativo | OpenTelemetry ou REST API | Mesmo | SDKs Python/JS apenas | Proxy HTTP (language-agnostic) |
| **Vendor lock-in** | Nenhum | Baixo (open source, dados migrável) | Médio (migração para self-host) | Alto (proprietário, focado em LangChain) | Médio |

#### Recomendação: **Abordagem faseada — Custom (Phase 1-2) → Langfuse Cloud (Phase 3) → Langfuse self-hosted (Phase 5+)**

**Justificativa:**

1. **Phase 1-2 (Custom)**: A tabela `llm_calls` existente já captura o necessário para tracking básico de custos. Adicionar eventos `:telemetry` para chamadas LLM (`:lanttern, :llm, :call, :start/:stop`) e um cron job Oban periódico para agregar custos por escola. Isso é baixo esforço e integra com o LiveDashboard existente.

2. **Phase 3 (Langfuse Cloud)**: Uma vez que o sistema de memória esteja implementado e as conversas se tornem mais complexas, adotar Langfuse Cloud para tracing e avaliação adequados. O tier Cloud começa gratuito (50k traces/mês) e escala para $29/mês (1M traces). Integração via OpenTelemetry — que tem forte suporte no Elixir/BEAM — ou REST API direta.

3. **Phase 5+ (Langfuse self-hosted)**: Quando o volume de traces justificar ou sensibilidade de dados exigir, migrar para Langfuse self-hosted no Kubernetes. A transição é direta porque a camada de integração (OpenTelemetry) não muda.

**Por que não LangSmith?** É proprietário, focado em LangChain (estamos removendo LangChain), e tem pricing por-seat. **Por que não Helicone?** É baseado em proxy, que não se encaixa em nossa arquitetura de Oban workers (a chamada LLM acontece server-side, não via proxy). **Por que Langfuse?** Open source, self-hostable, framework-agnostic, sem pricing por-seat, e sua arquitetura v4 (backed por ClickHouse) lida bem com escala.

Veja [Seção 4: Deep Dive: Langfuse](#4-deep-dive-langfuse) para análise técnica completa.

#### Perspectiva cross-language

| Dimensão | Elixir | Python | TypeScript |
|---|---|---|---|
| **Integração Langfuse** | OpenTelemetry ou REST API (sem SDK oficial) | **SDK oficial** — decorators nativos, auto-tracing, gestão de prompts | **SDK oficial** — mesmas features que Python |
| **LangSmith** | Sem SDK (apenas REST) | **Integração nativa** — auto-traces de chamadas LangChain/LangGraph, playground, datasets | LangChain.js auto-tracing |
| **Frameworks de avaliação** | Nenhum | **DeepEval** (testes de LLM estilo pytest — detecção de alucinação, scoring de relevância, checagem de toxicidade), **RAGAS** (avaliação de RAG baseada em pesquisa), **PromptFoo** (red-teaming de segurança, teste de prompt injection) | PromptFoo (funciona com TS), outros limitados |
| **Gestão de prompts** | Apenas em código (system prompts em `agent_chat.ex`) | Versionamento de prompts Langfuse/LangSmith, **DSPy** (otimização automática de prompts) | Versionamento de prompts Langfuse |

**Veredito**: Python tem um **ecossistema de observabilidade e avaliação significativamente melhor**. DeepEval, RAGAS e PromptFoo não têm equivalentes em Elixir — e avaliação é crítica para educação (segurança, garantia de qualidade). Esta é uma lacuna genuína. A abordagem faseada com Langfuse mitiga a lacuna de observabilidade, mas frameworks de avaliação permanecem uma vantagem exclusiva do Python. Se avaliação rigorosa de qualidade de AI se tornar um requisito, este é o segundo argumento mais forte (após orquestração) para um sidecar Python.

---

### Decisão 8: Monolith vs Microservice — AI deve viver fora do Elixir?

**Pergunta**: Ganharíamos ferramental significativamente melhor construindo features de AI como um serviço separado em Python ou TypeScript?

#### A resposta honesta: sim, o ferramental é melhor. A questão é se vale o custo.

O ecossistema de AI do Python é **objetivamente mais rico** que o do Elixir. As comparações cross-language nas Decisões 1-7 acima mostram lacunas reais em orquestração (LangGraph), avaliação (DeepEval/RAGAS), memória (mem0) e SDKs de providers (oficiais vs comunidade). Estas não são teóricas — representam ferramentas production-ready com grandes comunidades.

Mas qualidade de ferramental é apenas uma variável. A equação completa inclui custo operacional, acoplamento de domínio, expertise do time e complexidade arquitetural.

#### Opções

| Dimensão | Opção A: Monolith Elixir | Opção B: Sidecar Python (co-deployed) | Opção C: Microservice completo (deploy separado) |
|---|---|---|---|
| **Acesso ao ecossistema AI** | Apenas Elixir (ReqLLM, código customizado) | **Ecossistema Python completo** (LangGraph, DeepEval, SDKs oficiais) | Ecossistema completo Python ou TS |
| **Deployment** | Unidade única | Unidade única (mesmo pod/VM) | Unidades separadas |
| **Overhead de latência** | 0ms (in-process) | +5-10ms (localhost HTTP) | +25-50ms (network hop) |
| **Execução de tools** | Chamada direta de função (`Lessons.create_lesson/3`) | HTTP interno para Phoenix → lógica de negócio | API externa → Phoenix → lógica de negócio |
| **Carregamento de contexto** | Query Ecto direta (~5ms) | HTTP para Phoenix → query Ecto → serializar (~50-100ms) | Mesmo que sidecar mas pela rede |
| **Streaming PubSub** | Nativo | Bridge Redis ou webhook → Phoenix PubSub | Mesmo que sidecar |
| **Multiplicador de custo de infra** | 1x | 1.1-1.3x | 3.75-6x |
| **Requisito de time** | Devs Elixir | Elixir + 1-2 devs Python | Elixir + 2-4 devs Python + engenheiro de plataforma |
| **Auth/Scope** | Pattern matching nativo | Precisa passar scope ou duplicar auth | Mesmo + camada de auth de rede |
| **Acesso ao DB** | Compartilhado (Ecto) | PostgreSQL compartilhado (direto ou via API) | DB separado ou compartilhado (ambos têm problemas) |
| **Testabilidade** | Suite de testes única | Duas suites de teste, testes de integração necessários | Mesmo + contract testing |
| **Quando escolher** | AI é simples, time é pequeno, acoplamento de domínio é apertado | Precisa de capacidades Python específicas, tem expertise Python | AI precisa escalar independentemente, time >50 |

#### O trade-off central: Ecossistema vs Integração de Domínio

O AI agent do Lanttern não é um chatbot standalone — ele penetra profundamente no domínio da aplicação:

1. **System prompts** carregam de 6+ tabelas (configs de escola, agents, staff, templates, strands, lessons)
2. **Execução de tools** chama funções de negócio com autorização Scope e audit logging
3. **Updates em tempo real** fluem pelo Phoenix PubSub
4. **Injeção de memória** consulta memórias de usuário school-scoped
5. **Resolução de contexto** carrega entidades polimórficas com associações Ecto

Uma fronteira de microservice cortaria através desses pontos de acoplamento. O microservice ou:
- **Acessa o DB do Lanttern diretamente** (acoplamento forte, schema compartilhado, coordenação de migrations) — derrota o propósito da separação
- **Chama APIs do Phoenix para tudo** (latência, risco de stale, superfície de API para manter) — adiciona complexidade

#### Recomendação: **Opção A (monolith Elixir) agora, com caminho claro para Opção B (sidecar Python) quando necessidades específicas surgirem**

**Justificativa:**

1. **Necessidades atuais são atendidas.** O Lanttern precisa de um client LLM, tool calling, streaming e memória. ReqLLM + código customizado entrega isso. As features avançadas do LangGraph (checkpointing, multi-agent) ainda não são necessárias.

2. **Acoplamento de domínio é o fator decisivo.** O acoplamento mais apertado está em carregamento de contexto e execução de tools — ambos requerem acesso direto a Ecto schemas e autorização via Scope. Um microservice adiciona fricção no pior ponto possível.

3. **Dados da indústria corroboram.** 42% das organizações que adotaram microservices consolidaram de volta (pesquisa CNCF 2025). Amazon Prime Video alcançou 90% de redução de custos migrando de microservices para monolith.

4. **A válvula de escape do sidecar existe.** `AgentChat.LLM` é projetado para que a chamada de orquestração LLM possa ser redirecionada para um serviço externo. Quando capacidades Python forem necessárias, extraímos APENAS a orquestração LLM para um sidecar FastAPI co-deployed — sem mover lógica de domínio, auth ou acesso a dados.

#### Quando adotar um sidecar Python (Opção B)

| Gatilho | Por quê | O que extrair |
|---|---|---|
| Coordenação multi-agent necessária | LangGraph/CrewAI não têm equivalente em Elixir | Apenas orquestração de agents |
| RAG sobre grandes corpora de documentos | LlamaIndex está muito à frente | Processamento de documentos + retrieval |
| Avaliação rigorosa necessária | DeepEval/RAGAS/PromptFoo são Python-only | Pipeline de avaliação |
| Engenheiro de AI Python contratado | Pode ser dono do sidecar sem sobrecarregar o time Elixir | O que fizer mais sentido para ele |
| Time cresce além de 30 engenheiros | Velocidade independente do time de AI justificada | Orquestração completa de AI |

Veja [Seção 5: Deep Dive: Arquitetura Microservice](#5-deep-dive-arquitetura-microservice-e-ecossistemas-cross-language) para comparações detalhadas de ecossistema, diagramas de arquitetura e análise de custos.

---

## 3. Deep Dive: Vercel AI SDK

### O que é

O Vercel AI SDK (pacote npm `ai`) é um toolkit TypeScript para construir aplicações com AI. Apesar do nome, é **framework-agnostic** — funciona com React, Vue, Svelte e qualquer backend que produza o protocolo de streaming correto.

### Arquitetura

```
┌─────────────────────────────────────────────────┐
│  Aplicação React                                  │
│                                                   │
│  hook useChat()                                   │
│    ├── Gerencia estado de mensagens (user + asst) │
│    ├── Lida com streaming (auto-appenda tokens)   │
│    ├── Abort / retry / reload                     │
│    ├── Gerenciamento de auto-scroll               │
│    ├── Rendering de tool calls                    │
│    └── Endpoint de API configurável               │
│                                                   │
│  Renderers customizados de tool calls             │
│    └── ex: <LessonCard> para create_lesson        │
└───────────────────────┬─────────────────────────┘
                        │ POST /api/chat
                        │ Content-Type: text/event-stream
                        │ x-vercel-ai-ui-message-stream: v1
                        ▼
┌─────────────────────────────────────────────────┐
│  Backend (endpoint SSE Phoenix)                   │
│                                                   │
│  Produz Server-Sent Events por protocolo:         │
│    0:{text}              → token de texto         │
│    9:{tool_call_json}    → tool call iniciado     │
│    a:{tool_result_json}  → resultado de tool call │
│    e:{finish_json}       → stream finalizado      │
│    d:{usage_json}        → metadata de uso tokens │
│                                                   │
│  O backend controla modelo, prompts, tools —      │
│  o SDK apenas consome o stream.                   │
└─────────────────────────────────────────────────┘
```

### Como integra com Phoenix

1. **Endpoint SSE**: Um controller Phoenix dedicado (`AiStreamController`) lida com requests `POST /api/chat`. Autentica o usuário (cookie de sessão ou token), constrói o request LLM via `AgentChat.LLM`, faz stream de chunks do ReqLLM, e formata conforme o Vercel Data Stream Protocol.

2. **React island**: A UI do chat é montada como um React island dentro de uma página LiveView via Phoenix hook. O componente React usa `useChat({ api: "/api/chat" })` para conectar ao endpoint SSE.

3. **Bridge LiveView**: Dados não-chat (info do strand, configurações do usuário, navegação) continuam fluindo pelo LiveView. O React island recebe props iniciais do LiveView e pode comunicar de volta via eventos customizados.

### Prós

| Vantagem | Detalhe |
|---|---|
| **Streaming "just works"** | `useChat` lida com consumo de SSE, estado de mensagens, buffering, reconexão — zero código customizado |
| **Rendering de tool calls** | Quando o LLM chama uma tool, o SDK fornece callback para renderizar componentes React customizados (ex: `<LessonCard>`) em vez de texto puro |
| **Auto-scroll** | Gerenciamento de scroll nativo para interfaces de chat |
| **Abort / retry** | Usuário pode cancelar uma resposta em streaming ou tentar novamente uma falha — `useChat` gerencia as transições de estado |
| **Model agnostic** | O SDK não se importa com qual modelo o backend usa. Apenas consome o protocolo de stream. |
| **Comunidade enorme** | O SDK de frontend AI mais adotado. Padrões battle-tested, documentação extensiva, updates frequentes. |
| **Leve** | O pacote `ai` tem ~40KB. Sem runtime pesado. |

### Contras

| Desvantagem | Detalhe |
|---|---|
| **Requer React** | Lanttern é atualmente puro LiveView. Setup React está em progresso mas não pronto. |
| **Endpoint SSE = superfície de API paralela** | O endpoint SSE é separado do LiveView. Precisa de autenticação própria, proteção CSRF, rate limiting. |
| **Complexidade do bridge LiveView ↔ React** | Comunicar entre estado LiveView e um React island requer uma camada de bridge via hooks. Sincronização de estado complexa pode ser tricky. |
| **Dois paradigmas de rendering** | O app teria LiveView para tudo exceto chat, e React para chat. Esta abordagem de paradigma duplo adiciona overhead cognitivo. |
| **Mudanças no build tooling** | esbuild precisa ser configurado para compilar JSX, ou um pipeline Vite separado é necessário para o subtree React. |
| **Não necessário para v0** | LiveView consegue entregar streaming via PubSub e componentes ricos via function components. O valor do SDK só se materializa em escala ou para padrões interativos complexos. |

### Comparação com alternativas

| Feature | Vercel AI SDK | CopilotKit | assistant-ui |
|---|---|---|---|
| **Escopo** | Hooks de streaming frontend | Plataforma completa (frontend + backend) | Componentes React headless para chat |
| **Acoplamento backend** | Nenhum — qualquer backend SSE | SDK backend CopilotKit obrigatório | Nenhum — qualquer backend |
| **Streaming** | SSE (Data Stream Protocol) | AG-UI Protocol | Adapters customizados |
| **UI de tool calls** | Renderers customizados por tool | Rendering de actions nativo | Renderers customizados |
| **Complexidade** | Baixa (apenas hooks) | Alta (plataforma completa) | Média (biblioteca de componentes) |
| **Melhor para** | Backend customizado + frontend React | Apps AI full-stack | Máxima customização de UI |
| **Risco para Lanttern** | Baixo (focado, leve) | Alto (dependência de plataforma, conflita com backend Elixir) | Médio (comunidade menor) |

### Recomendação para o Lanttern

**Curto prazo (Phase 1-3)**: Não adotar o Vercel AI SDK. Usar LiveView para a UI do chat. A arquitetura backend deve ser projetada como UI-agnostic, para que a transição para React seja seamless quando pronta.

**Médio prazo (Phase 4-5)**: Uma vez que React islands estejam operacionais, adotar o Vercel AI SDK para a interface de chat. Implementar um controller Phoenix SSE que fala o Vercel Data Stream Protocol. Manter LiveView como framework geral da página, com o chat como React island.

**Evitar CopilotKit**: Seu SDK backend conflita com a arquitetura Elixir-centric do Lanttern. assistant-ui é uma alternativa viável se o time preferir mais controle sobre a UI, mas a comunidade e documentação do Vercel AI SDK o tornam a aposta mais segura.

---

## 4. Deep Dive: Langfuse

### O que é

Langfuse é uma **plataforma open-source de engenharia LLM** (adquirida pela ClickHouse em 2026, 24k+ stars no GitHub). Diferente de ferramentas de APM genéricas, ele entende nativamente conceitos específicos de LLM: uso de tokens, parâmetros de modelo, pares prompt/completion, scores de avaliação e sessões de conversa.

### Arquitetura (v4 — atual)

```
┌──────────────────────────────────────────────────┐
│  Plataforma Langfuse                              │
│                                                   │
│  ┌─────────────┐    ┌──────────────────────────┐ │
│  │   Web        │    │  Worker (Node.js)         │ │
│  │  (Next.js)   │    │  - Filas async BullMQ     │ │
│  │  - UI        │    │  - Processamento eventos  │ │
│  │  - REST API  │    │  - Pipelines avaliação    │ │
│  │  - OTLP API  │    └──────────┬───────────────┘ │
│  └──────┬───────┘               │                 │
│         │                       │                 │
│  ┌──────▼───────────────────────▼───────────────┐ │
│  │  ClickHouse (OLAP — traces, observations)     │ │
│  │  - Modelo de dados observation-centric (v4)   │ │
│  │  - Formato colunar para queries analíticas    │ │
│  │  - 20x mais rápido que v3                     │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  PostgreSQL (metadata — users, projects)      │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  Redis/Valkey (filas + cache)                 │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  S3/Blob (persistência de eventos + exports)  │ │
│  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Features principais

| Feature | O que faz | Por que importa para o Lanttern |
|---|---|---|
| **Tracing Distribuído** | Hierarquia de spans: Traces > Observations (spans/generations/events). Agrupamento por sessão. | Rastrear ciclo de vida completo da conversa: mensagem do usuário → construção de prompt → chamada LLM → execução de tool → resposta. Identificar gargalos. |
| **Gestão de Prompts** | Controle de versão, branching, caching, playground para testes. | Atualmente, prompts vivem no código (`agent_chat.ex`). Langfuse permite iteração de prompts por não-desenvolvedores sem deploys. |
| **Avaliação** | LLM-as-judge, labeling manual, pipelines de eval customizados, testes de regressão baseados em datasets. | Medir e melhorar qualidade do agente ao longo do tempo. Responder: "Nossos planos de aula estão melhorando?" |
| **Tracking de Custos** | Cálculo de custos por-modelo, por-usuário, por-sessão. Pricing customizado de modelos. | Substituir agregação manual da `llm_calls` por dashboards automatizados. Visibilidade de custos por-escola. |
| **Feedback de Usuários** | Coletar thumbs up/down, ratings, feedback customizado sobre outputs AI. | Fechar o loop de feedback. Professores avaliam planos de aula → dados fluem de volta para melhorar prompts. |
| **Analytics** | Dashboards customizados, análise de sessões, tracking de comportamento de usuários. | Entender como professores usam o agente. Quais tools são mais chamadas? Onde conversas falham? |

### Self-hosting

| Opção | Infraestrutura | Caso de uso |
|---|---|---|
| **Docker Compose** | VM única, 4+ vCPUs, 16GB+ RAM. Containers PostgreSQL + ClickHouse + Redis + Langfuse. | Desenvolvimento/staging. Não recomendado para produção (sem HA). |
| **Kubernetes (Helm)** | Cluster K8s com bancos gerenciados. Helm charts fornecidos. Min 2 réplicas web do Langfuse. | Produção. HA completo e auto-scaling. Pode apontar para instâncias existentes de PostgreSQL/ClickHouse/Redis. |

**Requisitos de infraestrutura:**
- Todos os componentes devem rodar com **timezone UTC** (não-UTC causa resultados de query incorretos)
- Mínimo: 2 instâncias web, auto-scale em 50% CPU
- Replicação adequada de Redis/ClickHouse para HA

**Custo de self-hosting:**
| Escala | Custo infra/mês | Custo DevOps/mês | Total |
|---|---|---|---|
| Pequena (<1M traces/mês) | $500-1.000 | ~$2.000 | ~$2.500 |
| Média (1-10M traces/mês) | $2.000-3.000 | ~$3.000 | ~$5.000 |
| Grande (10M+ traces/mês) | $5.000-15.000 | ~$5.000 | ~$10.000+ |

### Integração com Elixir

Não há SDK oficial Elixir da Langfuse. Opções de integração:

| Abordagem | Esforço | Qualidade | Recomendado? |
|---|---|---|---|
| **OpenTelemetry** | Médio | Excelente — suporte nativo BEAM, tracing distribuído, protocolo padrão | **Sim (recomendado)** |
| **REST API** | Baixo | Bom para casos simples. Batching manual necessário. | Para início rápido |
| **SDK da comunidade** (`workera-ai/langfuse_sdk`) | Baixo | Mantido pela comunidade, não oficial. Verificar maturidade. | Avaliar antes de depender |

**Padrão de integração recomendado:**

```
Aplicação Phoenix (Elixir)
    ↓
AgentChat.LLM (chamadas ReqLLM)
    ↓ wrap com spans OpenTelemetry
opentelemetry-erlang (pacote hex)
    ↓ export OTLP
Langfuse /api/public/otel endpoint
    ↓
ClickHouse (traces/observations)
```

**Implementação prática:**

```elixir
# Em AgentChat.LLM, envolver chamadas LLM com telemetry
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

A biblioteca OpenTelemetry se inscreve nesses eventos de telemetry e os exporta como spans para o endpoint OTLP da Langfuse. Isso é não-invasivo — o código de negócio emite eventos, a camada de infraestrutura cuida da exportação.

### Comparação de pricing

| Plano | Mensal | Traces/mês | Por 100K extra | Usuários | Retenção |
|---|---|---|---|---|---|
| **Hobby (Gratuito)** | $0 | 50.000 | — | 2 | 30 dias |
| **Core** | $29 | 1.000.000 | $8 | Ilimitados | 90 dias |
| **Pro** | $199 | 5.000.000 | $8 | Ilimitados | 2 anos |
| **Self-hosted** | $0 (software) | Ilimitados | — | Ilimitados | Ilimitado |

### Recomendação para o Lanttern

**Phase 1-2**: Usar telemetry customizado + tabela `llm_calls` existente. Adicionar eventos `:telemetry` para chamadas LLM. Criar cron job Oban para agregar custos por escola.

**Phase 3**: Adotar Langfuse Cloud (tier Hobby gratuito ou Core $29). Integrar via OpenTelemetry. Usar para tracing, dashboards de custo e experimentos iniciais de avaliação.

**Phase 5+**: Avaliar Langfuse self-hosted quando (a) volume de traces exceder 5M/mês, (b) sensibilidade de dados exigir on-premises, ou (c) features avançadas como gestão de prompts justificarem o investimento em infraestrutura.

---

## 5. Deep Dive: Arquitetura Microservice e Ecossistemas Cross-Language

### Ecossistema Python de AI — O que o Elixir não tem

#### Orquestração de Agents

| Framework | Status | O que faz | Equivalente Elixir |
|---|---|---|---|
| **LangGraph** | Production-ready (v1.0, Out 2025) | Agents stateful com checkpointing, time-travel debugging, human-in-the-loop, 5 modos de streaming, durable execution | **Nada** — nosso custom tool_call_loop é ~5% do feature set do LangGraph |
| **CrewAI** | Production-ready | Times multi-agent baseados em papéis. Defina agents com roles, goals, tools e deixe-os colaborar. | **Nada** — nenhum framework multi-agent em Elixir |
| **AG2/AutoGen** | Quase pronto (v1.0 vindo) | Cenários multi-agent complexos com execução de código, uso de tools e human-in-the-loop | **Nada** |
| **LlamaIndex** | Production-ready | Agents RAG-first, document loaders, chunking, vector stores, pipelines de retrieval | **Nada** — precisa construir RAG manualmente |

#### Structured Output e Validação

| Framework | Status | O que faz | Equivalente Elixir |
|---|---|---|---|
| **Instructor** | Production-ready (3M+ downloads/mês) | Outputs LLM estruturados schema-first com retries automáticos e validação | Validação com Ecto schema (manual, sem lógica de retry LLM) |
| **Pydantic AI** | Production-ready | Agents type-safe com dependency injection, streaming e observabilidade built-in | Nada equivalente |
| **DSPy** | Emergente | Otimização automática de prompts — escreve e ajusta prompts algoritmicamente | **Nada** — capacidade única |

#### Avaliação e Segurança

| Framework | Status | O que faz | Equivalente Elixir |
|---|---|---|---|
| **DeepEval** | Production-ready | Testes unitários estilo pytest para LLMs — detecção de alucinação, scoring de relevância, checagem de toxicidade | **Nada** |
| **RAGAS** | Production-ready | Avaliação de RAG baseada em pesquisa — faithfulness, relevância de resposta, precisão de contexto | **Nada** |
| **PromptFoo** | Production-ready | Red-teaming de segurança, teste de prompt injection, detecção de output nocivo | **Nada** |

#### Sistemas de Memória

| Sistema | O que faz | Equivalente Elixir |
|---|---|---|
| **mem0** | Camada de memória gerenciada — auto-categoriza, vector search, scoping por user/session/agent | Tabela customizada `user_ai_memories` (mais simples, mas adequada) |
| **MemGPT/Letta** | Memória de agent auto-editável com storage em camadas (core/archival/recall) | Nada equivalente |
| **LangGraph checkpointing** | Persistência de estado de conversa com time-travel e branching | Nada — usamos banco de dados para estado |

### Ecossistema TypeScript de AI — A opção frontend-native

| Framework | Ponto forte | O que adiciona sobre Elixir |
|---|---|---|
| **Vercel AI SDK** | Streaming SSE nativo, `useChat`, rendering de tool calls | Sem bridge Phoenix necessário — backend e frontend falam a mesma linguagem |
| **LangChain.js** | Framework AI JS mais abrangente | Suporte RAG, agent chains — mas um port do Python, não design nativo TS |
| **LangGraph.js** | Mesmas features que LangGraph Python | Agents stateful, streaming, checkpointing — em TypeScript |
| **Mastra** | Framework AI TypeScript-native | Abstrações limpas, routing built-in, emergente mas bem financiado |

### Diagramas de arquitetura

#### Opção B: Sidecar Python (co-deployed)

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

**Fluxo de dados para uma mensagem do usuário (sidecar):**

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

#### Opção C: Microservice completo (deploy separado)

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

**Complexidade adicional na Opção C:**
- Service discovery e health checks
- Autenticação de rede entre serviços
- Versionamento de API e contract testing
- Tracing distribuído entre serviços
- Deploys coordenados (breaking changes)
- Dois pipelines separados de CI/CD

### Comparação de custos operacionais

| Dimensão | Opção A: Monolith Elixir | Opção B: Sidecar Python | Opção C: Microservice completo |
|---|---|---|---|
| **Infraestrutura** | ~$5K/mês | ~$5.5-6.5K/mês (+10-30%) | ~$18-30K/mês (3.75-6x) |
| **Engenheiros necessários** | 2-3 Elixir | 2-3 Elixir + 1-2 Python | 2-3 Elixir + 2-4 Python + 1 plataforma |
| **Complexidade de deploy** | Pipeline único | Pipeline único (mesma unidade) | Dois pipelines + coordenação |
| **Monitoramento** | LiveDashboard + Oban Web | Mesmo + métricas FastAPI | Tracing distribuído obrigatório |
| **Resposta a incidentes** | Um codebase para debugar | Dois codebases, mesmo host | Dois codebases, problemas de rede |
| **Tempo até primeira feature** | Rápido (sem setup) | +1-2 semanas (setup FastAPI, camada bridge) | +4-6 semanas (infra, networking, auth) |

### Realidade do pool de contratação

| Linguagem | Desenvolvedores globais | Especializados em AI | Dificuldade de contratação para roles de AI |
|---|---|---|---|
| **Python** | ~3.2M contribuidores | 95% do trabalho de AI | Moderada — grande pool, alta demanda |
| **TypeScript** | ~3M contribuidores | ~5% do trabalho de AI | Fácil (geral) / Difícil (específico para AI) |
| **Elixir** | ~50K contribuidores | <1% do trabalho de AI | Muito difícil — pool minúsculo, quase nenhuma especialização em AI |

**Implicação prática**: Se o Lanttern precisar contratar um engenheiro de AI, ele quase certamente será um desenvolvedor Python. O padrão sidecar (Opção B) é a forma natural de integrar a expertise dele sem reescrever o codebase Elixir.

---

## 6. Deep Dive: Escolhendo o Stack Frontend — CopilotKit + AG-UI vs Vercel AI SDK vs assistant-ui

### O AG-UI Protocol

AG-UI (Agent-User Interaction Protocol) é um **padrão aberto** para comunicação agent↔frontend, adotado por Google, AWS, LangChain, Microsoft, Mastra e PydanticAI. Define um formato de eventos SSE estruturado, projetado especificamente para AI agents — não apenas chatbots.

**Tipos de evento:**

| Evento | Propósito | Exemplo |
|---|---|---|
| `RUN_STARTED` / `RUN_FINISHED` | Tracking de lifecycle do agent | Mostrar indicador "pensando..." |
| `TEXT_MESSAGE_START` / `CONTENT` / `END` | Streaming de tokens | Exibir texto conforme é gerado |
| `TOOL_CALL_START` / `TOOL_CALL_END` | Tracking de execução de tools | Mostrar "criando aula..." com spinner |
| `STATE_SNAPSHOT` | Broadcast de estado completo do agent | Sincronizar estado da conversa ao reconectar |
| `STATE_DELTA` | Updates incrementais de estado | Atualizar elementos UI específicos em tempo real |
| `STEP_STARTED` / `STEP_FINISHED` | Tracking de workflows multi-step | Mostrar progresso através do workflow do agent |

**Comparação com Vercel Data Stream Protocol:**

| Aspecto | AG-UI Protocol | Vercel Data Stream Protocol |
|---|---|---|
| **Projetado para** | AI agents com estado complexo | Interfaces de chat com streaming de texto |
| **Gestão de estado** | First-class (snapshots + deltas) | Não suportado |
| **Human-in-the-loop** | Eventos nativos para workflows de aprovação | Não suportado |
| **Detalhe de tool call** | Start, args, progresso, resultado, end | Start, resultado apenas |
| **Lifecycle do agent** | Eventos completos de lifecycle | Apenas sinal de done |
| **Workflows multi-step** | Eventos de tracking de steps | Não suportado |
| **Adoção** | Google, AWS, Microsoft, LangChain | Ecossistema Vercel |
| **Maturidade** | Mais novo (2025), crescendo rapidamente | Estabelecido (2024), amplamente usado |

### CopilotKit — Plataforma completa implementando AG-UI

CopilotKit é uma plataforma React que implementa o AG-UI Protocol, fornecendo componentes pré-prontos para interfaces de AI agents.

**Componentes:** `<CopilotChat>`, `<CopilotPopup>`, `<CopilotSidebar>`, `<CopilotTextarea>`

**Features principais:**
- **Generative UI**: Agent pode renderizar componentes React customizados inline (ex: lesson cards, diálogos de aprovação)
- **Sincronização de estado**: Sync em tempo real entre estado do agent e UI via eventos STATE_SNAPSHOT/DELTA
- **Human-in-the-loop**: Workflows de aprovação nativos (agent pausa, mostra UI de aprovação, retoma na ação do usuário)
- **Auto-tool rendering**: Tool calls automaticamente renderizam como elementos UI interativos
- **LangGraph nativo**: Integração direta via AG-UI — nenhuma camada de conversão necessária

**Prós:** UX de agent mais rica out of the box, protocolo AG-UI aberto, backing corporativo forte, open source core

**Contras:** Mais opinionado, modelo freemium, comunidade menor que Vercel AI SDK (~15k vs ~60k stars), footprint de dependência maior

### assistant-ui — Componentes headless de chat

assistant-ui é uma biblioteca de componentes React headless especificamente para interfaces de chat AI. Mais leve que CopilotKit e dá mais controle sobre a UI.

**Features principais:**
- **LangGraphMessageAccumulator**: Handler de streaming eficiente para eventos LangGraph
- **Componentes headless**: Você controla cada detalhe visual (sem estilos por padrão)
- **Adapter LangGraph Cloud**: Conexão direta à API do LangGraph Cloud/Studio
- **Conteúdo rico**: Markdown, code highlighting, attachments, voice input
- **UX de produção**: Auto-scroll, retry, abort, reconexão

**Prós:** Máxima customização visual, mais leve que CopilotKit, boa integração LangGraph, totalmente open source

**Contras:** Sem sincronização de estado, sem human-in-the-loop, sem generative UI, comunidade menor (~5k stars)

### Vercel AI SDK — Hooks leves de streaming

Já coberto no [Deep Dive: Vercel AI SDK](#3-deep-dive-vercel-ai-sdk). Adições para esta comparação:

**Limitações com backend LangGraph:** O adapter `@ai-sdk/langchain` converte o stream rico do LangGraph para o Data Stream Protocol mais simples. Essa conversão é **lossy** — eventos STATE, eventos de lifecycle e progresso detalhado de tools são descartados. Para chat simples, essa perda não importa. Para UX de agent (indicadores de status, workflows de aprovação, state sync), importa.

### Tabela de comparação: Todas as quatro opções

| Dimensão | CopilotKit + AG-UI | assistant-ui | Vercel AI SDK | AG-UI direto (sem lib) |
|---|---|---|---|---|
| **Protocolo** | AG-UI (eventos ricos) | Adapters customizados | Data Stream Protocol | AG-UI (raw) |
| **Eventos suportados** | TEXT, TOOL_CALL, STATE, HUMAN_APPROVAL, lifecycle | TEXT, TOOL_CALL (via adapters) | Texto + tool calls básicos | Todos os eventos AG-UI |
| **State sync** | Sim (snapshots + deltas) | Não | Não | Sim (handling manual) |
| **Human-in-the-loop** | Nativo | Não | Não | Sim (manual) |
| **Fit com LangGraph** | Mapeamento nativo 1:1 | Via LangGraphMessageAccumulator | Adapter com perda de info | 1:1 (manual) |
| **Comunidade** | ~15k stars + Google/AWS/MS | ~5k stars | ~60k stars | Padrão aberto, emergente |
| **Complexidade** | Opinionado (plataforma) | Headless (flexível) | Leve (apenas hooks) | DIY (máx controle) |
| **Customização UI** | Média (componentes prontos) | Alta (headless, sem estilos) | Média (hooks + custom) | Total |
| **Backend Python** | Nativo via AG-UI Python SDK | Via adapter LangGraph Cloud | Via fastapi-ai-sdk | Nativo |
| **Backend TypeScript** | Suportado | Suportado | Nativo | Suportado |
| **Backend Elixir** | Via endpoint SSE | Via endpoint SSE | Via endpoint SSE | Via endpoint SSE |
| **Pricing** | Open source + cloud pago | Open source | Open source | Open source |
| **Melhor para** | Agents complexos, UX rica | Chat customizável | Chat simples, qualquer backend | Controle total, time experiente |

### Quando usar cada — Exemplos de aplicações

**CopilotKit + AG-UI** — Melhor para interações complexas com agents:
- Plataforma educacional onde AI cria aulas e o professor aprova antes de salvar
- Agent de CRM que preenche forms, sugere ações e espera confirmação do usuário
- Sistema multi-agent onde a UI mostra qual agent está ativo e seu step atual
- Assistente de IDE que edita código e mostra diffs inline para aprovação

**assistant-ui** — Melhor para interfaces de chat customizáveis:
- Chat com attachments, voice input e rendering rico de markdown
- Projeto com design system existente que deve ser aplicado à UI de chat
- Integração com LangGraph Cloud onde o adapter cuida do backend
- App centrada em chat onde customização visual é mais importante que features de estado do agent

**Vercel AI SDK** — Melhor para chat simples e rápido de construir:
- Chatbot de suporte ao cliente com Q&A de texto
- Ferramenta de geração de conteúdo (escrever emails, resumir documentos)
- Features de autocompletion/sugestão
- Qualquer chat que não precisa de UI rica de tool call ou awareness de estado do agent

### Análise para requisitos do Lanttern

| Requisito Lanttern | CopilotKit | assistant-ui | Vercel AI SDK | Vencedor |
|---|---|---|---|---|
| Lesson card inline no chat | Tool rendering nativo | Custom (headless) | Custom renderer | **CopilotKit** |
| Professor aprova criação de aula | Human-in-the-loop nativo | Não suporta | Não suporta | **CopilotKit** |
| Streaming de tokens | Sim | Sim | Sim | Empate |
| Status do agent ("criando aula...") | Eventos STATE_DELTA | Não suporta | Não suporta | **CopilotKit** |
| Backend LangGraph (sidecar Python) | Mapeamento nativo | Via adapter | Adapter com perda | **CopilotKit** |
| Backend LiveView (monolith Elixir) | Endpoint SSE necessário | Endpoint SSE necessário | Endpoint SSE necessário | Empate |
| Customização visual (match design Lanttern) | Média | **Alta** | Média | **assistant-ui** |
| Comunidade e longevidade | Menor + backing corporativo | Pequena | Grande | Vercel (leve vantagem) |
| Simplicidade de setup | Médio | Simples | Mais simples | Vercel |

### Recomendação para o Lanttern (condicional)

**Se sidecar Python for adotado (backend LangGraph):**
→ **CopilotKit + AG-UI** — As features de UX de agent (human-in-the-loop, state sync, tool rendering) mapeiam diretamente para os requisitos do Lanttern. O workflow de aprovação de aulas sozinho justifica esta escolha.

**Se monolith Elixir continuar (sem LangGraph):**
→ **Vercel AI SDK** — Mais leve, mais simples, suficiente para chat básico com tool calls. O agent não tem os eventos ricos de estado do LangGraph, então as features avançadas do AG-UI seriam overhead não utilizado.

**Se ainda no LiveView (Fases 1-3):**
→ **Nenhum dos dois** — Usar LiveView PubSub para streaming e function components Phoenix para UI rica. Todas as três opções React requerem o setup de React islands.

**Independente da escolha**, a arquitetura backend (`AgentChat.LLM`, `AgentChat.Tools`, `AgentChat.ContextResolver`) permanece a mesma. A decisão de frontend é independente e reversível.

---

## 7. Arquitetura Alvo

### Diagrama de arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                        CAMADA UI                                  │
│                                                                   │
│  Fases 1-3: LiveView                                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ StrandChatLive / LessonChatLive / UniversalChatLive        │  │
│  │   └── ConversationComponent (LiveComponent)                │  │
│  │         - Rendering do message stream                      │  │
│  │         - Componentes inline ricos (cards de aula, etc.)   │  │
│  │         - Formulário de prompt, seletores agent/template   │  │
│  │         - Recebe updates push via PubSub                   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Fase 5+: React island (aditivo, não substituindo)                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ChatIsland (React + Vercel AI SDK)                         │  │
│  │   - useChat() conectado ao endpoint SSE /api/chat          │  │
│  │   - Renderers customizados de tool calls (LessonCard, etc.)│  │
│  │   - Auto-scroll, abort, retry                              │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
          ┌────────────────────┼─────────────────────┐
          │ 1. Usuário submete │ 6. PubSub broadcast  │ (ou SSE para React)
          │    prompt          │    {:message_added}   │
          ▼                    │                       │
┌──────────────────────────────┴───────────────────────────────────┐
│                     CAMADA DE CONTEXTO                             │
│                                                                   │
│  Lanttern.AgentChat (módulo de contexto)                          │
│    - create_conversation_with_message/3                           │
│    - add_user_message/3                                           │
│    - add_assistant_message/3                                      │
│    - list_conversation_messages/2                                 │
│    - subscribe/broadcast PubSub                                   │
│                                                                   │
│  Lanttern.AgentChat.LLM (NOVO — abstração LLM)                   │
│    - run_completion/4  (substitui run_llm_chain)                  │
│    - stream_completion/4  (Phase 4)                               │
│    - build_messages/3                                             │
│    - tool_call_loop/3  (substitui while_needs_response LangChain) │
│    - extract_response/1                                           │
│    → Usa ReqLLM internamente. NENHUM tipo LLM vaza pra fora.     │
│                                                                   │
│  Lanttern.AgentChat.Tools (NOVO — registro de tools)              │
│    - define_tools/2  (retorna specs de tools para LLM)            │
│    - execute_tool/3  (despacha para funções de contexto de neg.)  │
│    - Tools: create_lesson, update_lesson, set_conversation_title  │
│                                                                   │
│  Lanttern.AgentChat.Memory (NOVO — Phase 3)                       │
│    - list_user_memories/2                                         │
│    - create_memory/2                                              │
│    - summarize_conversation/2                                     │
│    - inject_memory_messages/2                                     │
│                                                                   │
│  Lanttern.AgentChat.ContextResolver (NOVO — Phase 2)              │
│    - resolve/1  (conversation_id -> system messages)              │
│    - register_context/3                                           │
│    - context_to_system_messages/1  (por context_type)             │
└──────────────────────────────┬───────────────────────────────────┘
                               │
          ┌────────────────────┼─────────────────────┐
          │ 2. Oban.insert()   │ 5. AgentChat         │
          │                    │    .add_assistant_msg  │
          ▼                    │    .broadcast          │
┌──────────────────────────────┴───────────────────────────────────┐
│                      CAMADA DE WORKERS                            │
│                                                                   │
│  Lanttern.ChatResponseWorker (Oban, queue: :ai)                   │
│    1. Resolver scope do user_id                                   │
│    2. Resolver modelo (args → config escola → app default)        │
│    3. Buscar conversa + mensagens                                 │
│    4. Injetar memória  (AgentChat.Memory — Phase 3)               │
│    5. Resolver contexto (AgentChat.ContextResolver — Phase 2)     │
│    6. Chamar AgentChat.LLM.run_completion/4                       │
│    7. Lidar com tool calls via AgentChat.Tools                    │
│    8. Persistir resposta + model call                             │
│    9. Broadcast via PubSub                                        │
│   10. Trigger atualização de memória (Phase 3)                    │
│                                                                   │
│  Lanttern.MemorySummaryWorker (NOVO — Phase 3, Oban, queue: :ai)  │
│    - Acionado após fim de conversa                                │
│    - Resume conversa em entradas de memória                       │
│                                                                   │
│  Lanttern.CostAggregationWorker (NOVO — Phase 4, Oban cron)       │
│    - Agregação periódica de llm_calls para relatórios de custo    │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               │ 3. ReqLLM.generate_text/3
                               │    (ou stream_text/3 na Phase 4)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CAMADA DE CLIENT LLM                             │
│                                                                   │
│  ReqLLM (unificado, baseado em Req)                               │
│    - OpenAI, Anthropic, Google, Mistral, Groq, AWS Bedrock...     │
│    - Suporte a tool calling                                       │
│    - Suporte a streaming SSE                                      │
│    - Middleware Req para retries, logging, telemetry               │
│                                                                   │
│  LLMDB (catálogo de validação de modelos)                         │
│    - LLMDB.allowed?/1                                             │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               │ 4. Eventos Telemetry
                               │    [:lanttern, :llm, :call, ...]
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAMADA DE OBSERVABILIDADE                         │
│                                                                   │
│  Fases 1-2: Telemetry + tabela llm_calls + LiveDashboard          │
│  Fase 3+:   OpenTelemetry → Langfuse (Cloud ou self-hosted)       │
└─────────────────────────────────────────────────────────────────┘
```

### Regras de fronteira entre módulos

| Módulo | Responsabilidade | Depende De | NÃO depende de |
|---|---|---|---|
| `AgentChat` | Acesso a dados (CRUD), PubSub | Ecto, PubSub | ReqLLM, qualquer lib LLM |
| `AgentChat.LLM` | Interação LLM: prompts, completion, tool loop | ReqLLM, LLMDB | Ecto, PubSub, Oban |
| `AgentChat.Tools` | Definições de tools e dispatch de execução | Contextos de negócio (Lessons, etc.) | ReqLLM, Ecto |
| `AgentChat.Memory` | CRUD de memória, sumarização, injeção | Ecto, AgentChat.LLM (para sumarização) | PubSub, Oban |
| `AgentChat.ContextResolver` | Resolução polimórfica de contexto | Ecto, contextos de negócio | LLM, PubSub |
| `ChatResponseWorker` | Orquestração: conecta todos os módulos | Todos os módulos AgentChat | LiveView |
| `ConversationComponent` | Rendering UI, interação do usuário | AgentChat (contexto apenas) | LLM, Tools, Memory, Worker |

**Fronteira crítica**: Nenhum tipo de biblioteca LLM vaza para fora de `AgentChat.LLM`. O módulo de contexto trabalha com strings e maps Elixir puros. Se ReqLLM for substituído depois, apenas `AgentChat.LLM` muda.

---

## 8. Evolução do Schema do Banco de Dados

### Phase 1: Contextos polimórficos de conversa

```sql
-- Substituir strand_agent_conversations por context links polimórficos
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

**Migração de dados**: Migrar linhas de `strand_agent_conversations` para `conversation_contexts`:
- Cada linha se torna 1 ou 2 linhas em `conversation_contexts` (`context_type: "strand"` + opcionalmente `context_type: "lesson"`)
- Deixar `strand_agent_conversations` como está (dívida técnica, regra 7 do CLAUDE.md)

### Phase 2: Metadata de mensagens + memória de usuário

```sql
-- Metadata rica de mensagens (tool calls, componentes UI)
ALTER TABLE agent_messages ADD COLUMN metadata JSONB DEFAULT '{}';

-- Memória AI do usuário
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

**Estrutura do metadata de mensagens:**

```json
{
  "tool_calls": [
    {"name": "create_lesson", "args": {"moment_id": 1, "description": "..."}}
  ],
  "tool_results": [
    {"name": "create_lesson", "result": {"lesson_id": 42, "status": "ok"}}
  ],
  "ui_component": "lesson_card",
  "ui_data": {"lesson_id": 42, "lesson_name": "Introdução a Frações"}
}
```

### Phase 3: Agregação de tracking de custos

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

### Phase 4: Configuração de orçamento de tokens

```sql
-- Adicionar à tabela school_ai_configs existente
ALTER TABLE school_ai_configs ADD COLUMN monthly_token_budget BIGINT;
ALTER TABLE school_ai_configs ADD COLUMN budget_alert_threshold FLOAT DEFAULT 0.8;
```

---

## 9. Roadmap de Implementação

### Phase 1: Consolidação de Bibliotecas + Abstração LLM (~2 semanas)

**Objetivo**: Remover dependência do LangChain; estabelecer fronteiras de módulos limpas.

| Passo | Tarefa | Arquivos afetados | Risco |
|---|---|---|---|
| 1.1 | Criar módulo `Lanttern.AgentChat.LLM` com `run_completion/4` que wrappa ReqLLM | Novo: `lib/lanttern/agent_chat/llm.ex` | Baixo |
| 1.2 | Criar módulo `Lanttern.AgentChat.Tools`; extrair definições de tools de `agent_chat.ex` | Novo: `lib/lanttern/agent_chat/tools.ex`; Modificado: `agent_chat.ex` | Baixo |
| 1.3 | Implementar tool call loop em `AgentChat.LLM` (substitui `while_needs_response`) | `agent_chat/llm.ex` | **Médio** — deve lidar com tool calls multi-turn corretamente |
| 1.4 | Reescrever `run_llm_chain/4` para usar `AgentChat.LLM.run_completion/4` | `agent_chat.ex` | Médio |
| 1.5 | Reescrever `ChatResponseWorker` para usar `AgentChat.LLM` ao invés de `ChatOpenAI` | `workers/chat_response_worker.ex` | Médio |
| 1.6 | Reescrever `rename_conversation_based_on_chain/3` para usar `AgentChat.LLM` | `agent_chat.ex` | Baixo |
| 1.7 | Atualizar testes: substituir mocks Mimic do LangChain por stubs ReqLLM | Arquivos de teste | Médio |
| 1.8 | Remover `{:langchain, "0.4.0"}` de `mix.exs`; remover config LangChain | `mix.exs`, `config/*.exs` | Baixo |
| 1.9 | Adicionar eventos `:telemetry` para chamadas LLM | `agent_chat/llm.ex` | Baixo |

**Entregável**: Todas as features AI funcionam identicamente ao que é hoje, mas utilizando ReqLLM através da abstração `AgentChat.LLM`. LangChain removido das dependências.

**Verificação**:
- Todos os testes existentes passam
- Teste manual: criar conversa, enviar mensagem, verificar resposta
- Teste manual: usar tool create_lesson, verificar que aula é criada
- Teste manual: verificar que auto-rename funciona
- `mix deps` não mostra dependência do LangChain

### Phase 2: Contexto Universal + Mensagens Ricas (~2 semanas)

**Objetivo**: Sistema polimórfico de contexto; metadata de mensagens para UI rica.

| Passo | Tarefa |
|---|---|
| 2.1 | Criar migration e schema Ecto para `conversation_contexts` |
| 2.2 | Criar módulo `Lanttern.AgentChat.ContextResolver` |
| 2.3 | Escrever migração de dados de `strand_agent_conversations` para `conversation_contexts` |
| 2.4 | Adicionar coluna `metadata` JSONB em `agent_messages` |
| 2.5 | Modificar `ChatResponseWorker` para usar `ContextResolver` na construção de system prompts |
| 2.6 | Quando tools executam (ex: `create_lesson`), armazenar referência da entidade no metadata da mensagem |
| 2.7 | Modificar `ConversationComponent` para renderizar componentes inline ricos baseados em `message.metadata` |
| 2.8 | Criar componente inline de card de aula para o conversation stream |

**Entregável**: Conversas podem ser vinculadas a qualquer tipo de entidade. Resultados de tool calls renderizam como componentes UI ricos (cards de aula) ao invés de texto plano.

**Verificação**:
- Conversas de strand existentes continuam funcionando (migração de dados verificada)
- Novas conversas criam linhas em `conversation_contexts`
- Quando AI cria uma aula, um card de aula aparece inline no chat
- Context resolver carrega system messages corretas por tipo de entidade

### Phase 3: Sistema de Memória (~2 semanas)

**Objetivo**: Memória de usuário entre conversas.

| Passo | Tarefa |
|---|---|
| 3.1 | Criar migration e schema Ecto para `user_ai_memories` |
| 3.2 | Criar módulo `Lanttern.AgentChat.Memory` |
| 3.3 | Criar job Oban `Lanttern.MemorySummaryWorker` |
| 3.4 | Adicionar injeção de memória Layer 0 na construção de prompts |
| 3.5 | Adicionar lógica de close/checkpoint de conversa que aciona sumarização de memória |
| 3.6 | Adicionar página de gestão de memória (staff pode visualizar/deletar próprias memórias) |
| 3.7 | Integrar Langfuse Cloud (OpenTelemetry ou REST API) |

**Entregável**: O agente lembra preferências do usuário e interações passadas entre conversas. Langfuse fornece tracing e dashboards de custo.

**Verificação**:
- Completar uma conversa, iniciar uma nova — agente referencia informações da conversa anterior
- Entradas de memória visíveis nas configurações do staff
- Deletar uma memória remove-a de prompts futuros
- Dashboard Langfuse mostra traces com contagem de tokens

### Phase 4: Streaming + Controles de Custo (~2 semanas)

**Objetivo**: Streaming de tokens em tempo real; limites de uso.

| Passo | Tarefa |
|---|---|
| 4.1 | Adicionar path de streaming em `AgentChat.LLM` usando streaming do ReqLLM |
| 4.2 | Adicionar eventos PubSub de chunk (`{:chunk, text}`) |
| 4.3 | Atualizar `ConversationComponent` para rendering incremental de mensagens |
| 4.4 | Criar tabela `ai_usage_reports` e `CostAggregationWorker` |
| 4.5 | Adicionar `monthly_token_budget` a `school_ai_configs` |
| 4.6 | Adicionar verificação de enforcement de orçamento antes de chamadas LLM |
| 4.7 | Adicionar dashboard de uso para admins de escola |

**Entregável**: Respostas AI em streaming. Escolas podem definir orçamentos de tokens. Relatórios de uso.

**Verificação**:
- Tokens aparecem conforme são gerados (sem mais espera pela resposta completa)
- Enforcement de orçamento previne chamadas quando orçamento é excedido
- Dashboard de uso mostra breakdown de custo por-escola, por-modelo

### Phase 5: File Uploads + Avaliação React (Sprint 5+)

**Objetivo**: Suporte a contexto baseado em arquivos; avaliar React para UI do chat.

| Passo | Tarefa |
|---|---|
| 5.1 | Adicionar suporte a upload de arquivos em conversas (LiveView uploads) |
| 5.2 | Extração de texto de PDF/documentos para injeção de contexto |
| 5.3 | Criar controller Phoenix SSE para Vercel AI SDK Data Stream Protocol |
| 5.4 | Criar React island de chat com hook `useChat` do Vercel AI SDK |
| 5.5 | Avaliar deploy self-hosted do Langfuse |
| 5.6 | Implementar enforcement server-side de cooldown do ILP |

**Entregável**: Uploads de arquivo funcionam. React island de chat disponível junto com versão LiveView.

---

## 10. Avaliação de Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| API de tool call do ReqLLM não suporta loop multi-turn | Média | **Alto** | Verificar API de tool calling do ReqLLM no Phase 1 Passo 1.3 antes de comprometer. Fallback: implementar loop de tool call via HTTP raw (ReqLLM é apenas Req por baixo). |
| Extração de tokens do ReqLLM difere do formato de metadata do LangChain | Média | Baixo | Escrever adapter em `AgentChat.LLM` que normaliza formato de resposta. Isolado por design. |
| Sumarização de memória produz resumos de baixa qualidade | Média | Médio | Começar com resumos extrativos simples. Iterar na qualidade do prompt. Limitar tamanho da memória. Permitir que usuários deletem memórias ruins. |
| Tabela polimórfica de contexto causa complexidade de queries | Baixa | Baixo | Índice em `(context_type, context_id)`. Queries são sempre scoped por `conversation_id` (FK indexada). |
| Streaming LiveView tem latência perceptível vs SSE | Baixa | Baixo | Broadcast PubSub é sub-milissegundo dentro do mesmo node. UX aceitável. |
| Biblioteca ReqLLM deixa de ser mantida | Baixa | **Alto** | A camada de abstração (`AgentChat.LLM`) isola o app — substituição afeta exatamente um módulo. |
| Setup de React islands demora mais que o esperado | Média | Baixo | Arquitetura é UI-agnostic por design. Path LiveView continua funcionando independente do timeline do React. |
| Complexidade de integração Langfuse com Elixir | Média | Médio | Começar com REST API (mais simples). Graduar para OpenTelemetry quando confortável. SDK da comunidade como bridge. |
| Breaking changes ao migrar do LangChain | Baixa | Médio | Migração é reescrita de 2 arquivos, não refatoração do app inteiro. Testes abrangentes validam comportamento. |
| Tool call loop tem edge cases (timeout, execução parcial) | Média | Médio | Copiar padrão battle-tested de timeout do LangChain (5 min). Adicionar tratamento de erro estruturado. Testar com chamadas de tool simuladas com lentidão. |
