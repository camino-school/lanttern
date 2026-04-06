# Arquitetura AI Agent — Perguntas e Respostas

> Documento complementar ao `ai-agent-feature-plan-pt.md`
>
> Perguntas antecipadas do time de desenvolvimento sobre decisões arquiteturais, trade-offs e detalhes de implementação.

---

## Sumário

1. [Camada de Client LLM (LangChain → ReqLLM)](#1-camada-de-client-llm)
2. [Orquestração de Agents (Oban)](#2-orquestração-de-agents)
3. [Chat UI e Frontend (LiveView → React)](#3-chat-ui-e-frontend)
4. [Streaming](#4-streaming)
5. [Memória do Usuário](#5-memória-do-usuário)
6. [Contexto Universal de Conversas](#6-contexto-universal-de-conversas)
7. [Observabilidade (Langfuse)](#7-observabilidade)
8. [Migração e Rollback](#8-migração-e-rollback)
9. [Testes](#9-testes)
10. [Performance e Custos](#10-performance-e-custos)
11. [Segurança e Propriedade de Dados](#11-segurança-e-propriedade-de-dados)
12. [Timeline e Priorização](#12-timeline-e-priorização)
13. [Detalhes do Vercel AI SDK](#13-detalhes-do-vercel-ai-sdk)
14. [Detalhes do Langfuse](#14-detalhes-do-langfuse)
15. [Ecossistema Jido](#15-ecossistema-jido)
16. [Monolith vs Microservice](#16-monolith-vs-microservice)
17. [CopilotKit vs Vercel AI SDK vs assistant-ui](#17-copilotkit-vs-vercel-ai-sdk-vs-assistant-ui)

---

## 1. Camada de Client LLM

### P: Por que remover LangChain ao invés de remover ReqLLM? LangChain tem mais features.

LangChain tem mais features, mas a maioria não é usada pelo Lanttern. As únicas features do LangChain que realmente usamos são:

1. `LLMChain` com `while_needs_response` — um loop de tool-call (~25 linhas de código customizado para substituir)
2. `ChatOpenAI` — instanciação de modelo (uma linha com ReqLLM)
3. `Function`/`FunctionParam` — definições de tools (mais simples no ReqLLM com `ReqLLM.Tool`)
4. Construtores de `Message` — construção de mensagens (equivalente direto no `ReqLLM.Context`)

Estamos pagando por um framework inteiro mas usando ~5% dele. ReqLLM é mais enxuto, já está no projeto, já testado, suporta nativamente 10+ provedores, e segue convenções Elixir mais de perto. O custo de manter LangChain (overhead cognitivo de duas bibliotecas, dois padrões de teste, duas configs) supera o custo de reescrever 25 linhas de código de orquestração.

### P: O que exatamente é o "tool call loop" que precisamos construir? Não é complexo?

O tool call loop substitui o `mode: :while_needs_response` do LangChain. Aqui está o que ele faz:

1. Enviar mensagens + definições de tools para o LLM
2. Se a resposta do LLM contém um tool call → executar a tool → appendar o resultado às mensagens → voltar ao passo 1
3. Se a resposta do LLM é texto puro → retorná-la

Em pseudocódigo:

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

São aproximadamente 25-30 linhas. O guarda `max_iterations` previne loops infinitos. O timeout de 5 minutos do LangChain é substituído por um timeout na própria função `call_llm`.

### P: E se o ReqLLM não suportar tool calling da forma que precisamos?

ReqLLM v1.6+ suporta tool calling via `ReqLLM.Tool`. A API é:

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

Se o tool calling do ReqLLM não lidar com algum edge case específico, ReqLLM é construído sobre Req (um client HTTP composável). Podemos sempre descer para a camada HTTP raw e enviar os parâmetros de tool call diretamente para a API do provedor. Isso é uma rede de segurança, não um caminho esperado.

**Passo de verificação**: Phase 1 Passo 1.3 inclui explicitamente a verificação da API de tool calling do ReqLLM antes de comprometer com a migração. Se não funcionar, construímos um wrapper fino sobre Req que lida com o protocolo de tool calling da OpenAI diretamente.

### P: ReqLLM suporta 10+ provedores, mas precisamos disso de verdade? Só usamos OpenAI.

Hoje, sim. Mas o plano identifica explicitamente **lock-in em provedor único** como uma lacuna atual. Escolas podem querer usar diferentes modelos (Anthropic para tarefas criativas, Google para multilíngue, modelos locais para escolas com dados sensíveis). A camada de abstração (`AgentChat.LLM`) combinada com o suporte multi-provider do ReqLLM significa que trocar provedores é uma mudança de configuração, não uma mudança de código.

Mesmo se ficarmos na OpenAI pelos próximos 6 meses, o custo do suporte multi-provider é zero — o ReqLLM já fornece isso. Não é algo que estamos construindo; é algo que ganhamos de graça.

### P: Remover LangChain não vai quebrar os testes existentes?

Sim, os testes existentes que mockam LangChain (via `Mimic.copy(LangChain.Chains.LLMChain)`) precisarão ser reescritos. Isso é Phase 1 Passo 1.7. Os novos testes usarão o mesmo padrão de `ReqLLMStub` já estabelecido para a feature de ILP — injeção de dependência do módulo LLM, não mocks específicos de biblioteca.

A reescrita dos testes é na verdade uma melhoria: injeção de dependência é mais confiável e simples que mocking baseado em Mimic. A superfície de testes é contida em `agent_chat_test.exs` e `chat_response_worker_test.exs`.

### P: E se o ecossistema do LangChain Elixir evoluir? E se ficar muito melhor?

LangChain para Elixir (v0.4.0) é uma porta da comunidade do ecossistema LangChain Python/JS. Sua cadência de updates é incerta e não segue idiomas Elixir de perto. Mesmo que melhore, nossa arquitetura isola o client LLM dentro de `AgentChat.LLM` — se uma biblioteca melhor surgir (LangChain, Jido, ou algo novo), mudamos um módulo, não o app inteiro.

A decisão arquitetural não é "ReqLLM para sempre" — é "uma biblioteca agora, atrás de uma abstração que torna a troca barata."

---

## 2. Orquestração de Agents

### P: Por que não usar Jido agents ao invés de Oban? Jido é projetado especificamente para AI agents.

Jido v2.0 introduz agents baseados em GenServer com gestão de estado, directives e execução em runtime. São features poderosas — para o problema certo. Nosso problema atual não precisa delas.

O agent chat do Lanttern é stateless entre requests: o usuário envia uma mensagem, o sistema processa, armazena o resultado e faz broadcast. Todo o estado vive no PostgreSQL. Não há necessidade de estado in-memory de agente, coordenação multi-agent, ou state machines complexas.

Jido adicionaria:
- Nova supervision tree para gerenciar
- Novas considerações de deploy (lifecycle do processo do agente)
- Novos padrões de teste (teste de GenServer vs teste de job Oban)
- Novos conceitos para o time aprender (directives, signals, command function)

Para zero benefício sobre o que o Oban já fornece (retries, unique constraints, pruning, dashboard, isolamento de testes).

**Quando Jido faz sentido**: Se algum dia precisarmos de agentes que coordenam entre si, mantêm estado long-running, ou executam workflows multi-step complexos onde a state machine não é trivialmente representável em banco de dados. Esse dia pode chegar — mas não é hoje.

### P: Se adicionarmos streaming com Task.Supervisor (Phase 4), não vamos ter dois paths de execução? Não fica bagunçado?

Sim, haverá dois paths. Mas servem propósitos diferentes:

1. **Path Oban** (não-streaming): Confiável, retryable, baseado em jobs. Usado para a chamada LLM principal. Sobrevive a restarts do servidor. Tem unique constraints. Registra no dashboard Oban.
2. **Path Task** (streaming): Fire-and-forget dentro do lifecycle de um request. Faz stream de chunks via PubSub. Não sobrevive a restarts (mas streaming é inerentemente atrelado a uma conexão ativa).

O worker decide qual path usar:

```elixir
def perform(%Oban.Job{args: %{"streaming" => true} = args}) do
  Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
    stream_response(args)
  end)
end

def perform(%Oban.Job{args: args}) do
  batch_response(args)
end
```

Não são duas arquiteturas competindo — é um orquestrador (Oban) com duas estratégias de execução. A complexidade fica contida no módulo do worker.

### P: O que acontece se o job Oban falhar durante um tool call?

O comportamento atual é preservado: Oban faz retry do job (até `max_attempts: 3`). O tool call é idempotente por design — se `create_lesson` for chamado duas vezes com os mesmos parâmetros, a segunda chamada ou cria uma duplicata (que o usuário pode deletar) ou falha se houver constraint de unicidade.

Para operações não-idempotentes, o resultado do tool call deve ser armazenado no banco de dados antes do broadcast. No retry, o worker verifica se o tool call já foi executado (checando message metadata) e pula a re-execução.

---

## 3. Chat UI e Frontend

### P: O setup React já está em progresso. Por que não esperar e ir direto para React + Vercel AI SDK?

Três razões:

1. **Risco de timeline**: O timeline do setup React é incerto. Bloquear arquitetura AI backend em infraestrutura frontend atrasaria o projeto inteiro.
2. **Arquitetura backend-first**: O backend (abstração LLM, resolução de contexto, memória, tools) é o mesmo independente da tecnologia frontend. Construí-lo agora com LiveView significa que está pronto para React quando React estiver pronto.
3. **LiveView é suficiente para v0**: O chat precisa exibir mensagens, mostrar estados de loading, renderizar resultados de tool call como componentes inline, e (depois) fazer stream de tokens. LiveView lida com tudo isso nativamente. O valor do Vercel AI SDK está na conveniência (auto-scroll, abort, reconnect) — bom ter, não bloqueante.

O plano de transição é explícito: **Phase 1-3 = LiveView; Phase 4-5 = React island adicionado junto com LiveView**. Ambos os paths coexistem. Sem rip-and-replace.

### P: Se usarmos LiveView agora, não vamos ter que reescrever toda a UI do chat quando migrarmos para React?

Não. A reescrita é apenas da **camada de template** (HTML/HEEx → JSX). O contrato do backend não muda:

- Funções de contexto `AgentChat`: mesma API independente do consumidor
- Eventos PubSub: mesmos eventos se consumidos por LiveView ou encaminhados para SSE
- Schema de mensagem: mesmo `metadata` JSONB independente de como é renderizado
- Definições de tools: mesmo módulo `AgentChat.Tools`

O que muda ao adicionar React:
1. Um novo controller Phoenix (`AiStreamController`) que converte eventos PubSub em SSE
2. Um componente React que usa `useChat` para consumir o stream SSE
3. Um LiveView hook que monta o React island

O que NÃO muda: `AgentChat`, `AgentChat.LLM`, `AgentChat.Tools`, `AgentChat.Memory`, `AgentChat.ContextResolver`, `ChatResponseWorker`, `MemorySummaryWorker`, todos os schemas Ecto, todas as migrations.

### P: Por que Vercel AI SDK ao invés de CopilotKit? CopilotKit parece mais completo.

CopilotKit é uma **plataforma completa** — inclui SDK backend, sua própria orquestração de agentes (AG-UI Protocol) e oferta cloud. Adotar CopilotKit significa:

1. **Conflito de backend**: CopilotKit espera que você use seu SDK backend para comunicação com agentes. A lógica de agente do Lanttern vive em Elixir (Oban workers, ReqLLM, Phoenix PubSub). O SDK backend Node.js do CopilotKit não integra com isso.
2. **Vendor lock-in**: CopilotKit tem modelo freemium com tiers enterprise pagos. O AI SDK é totalmente open source.
3. **Over-engineering**: Não precisamos de uma plataforma. Precisamos de um hook de streaming de chat. Vercel AI SDK é exatamente isso — `useChat()` e nada mais.

CopilotKit faz sentido para times construindo um app novo com AI no core e sem backend existente. Lanttern tem um backend Elixir maduro. Adicionar o backend do CopilotKit por cima criaria um sistema paralelo que luta com Oban/PubSub.

### P: E o assistant-ui? Parece mais customizável que o Vercel AI SDK.

assistant-ui é uma biblioteca de componentes React headless especificamente para UIs de chat AI. É uma boa biblioteca com controle granular sobre cada elemento de UI. Os trade-offs vs Vercel AI SDK:

| Aspecto | Vercel AI SDK | assistant-ui |
|---|---|---|
| **Comunidade** | ~60k stars no GitHub, adoção massiva | ~5k stars, crescendo |
| **Documentação** | Extensiva, cobre backends não-Next.js | Boa, menos cobertura para backends customizados |
| **Protocolo backend** | Data Stream Protocol bem definido | Adapters customizados (mais flexível, mais trabalho) |
| **Streaming** | Nativo via useChat | Requer configuração de adapter |
| **Risco** | Muito baixo (backing da Vercel, padrão da indústria) | Baixo-médio (comunidade menor) |

Ambos são viáveis. A recomendação é Vercel AI SDK porque seu Data Stream Protocol é bem documentado para backends customizados (que é o nosso caso — Phoenix, não Next.js), e o tamanho da comunidade dá confiança na manutenção a longo prazo.

Se o time avaliar ambos durante Phase 5 e preferir a flexibilidade do assistant-ui, o backend não muda. O endpoint SSE serve o mesmo protocolo de qualquer forma.

### P: Poderíamos usar LiveView para tudo incluindo streaming e pular React inteiramente?

Sim, tecnicamente. LiveView pode fazer stream de tokens via PubSub, renderizar componentes ricos, e lidar com todas as interações do chat. A questão é se o time quer investir em construir:

- Lógica de auto-scroll (scroll para baixo conforme tokens chegam, mas não se o usuário scrollou para cima)
- Tratamento de abort (cancelar uma chamada LLM em progresso)
- Lógica de reconexão (o que acontece quando o WebSocket cai no meio do stream?)
- Display otimista de mensagem (mostrar mensagem do usuário imediatamente antes da confirmação do servidor)
- Atalhos de teclado (enviar no Enter, nova linha no Shift+Enter com tratamento adequado de cursor)

Esses são todos problemas resolvidos no Vercel AI SDK. Construí-los em LiveView é possível mas consome tempo. A recomendação é: **LiveView por enquanto, React para quando o investimento em UX justificar.**

---

## 4. Streaming

### P: PubSub streaming não vai adicionar latência comparado a SSE direto?

Broadcast PubSub dentro do mesmo node Erlang é sub-milissegundo. O caminho é:

```
Chunk ReqLLM → Processo Worker → PubSub.broadcast → Parent LiveView → send_update → Re-render do Component
```

Latência adicional total vs SSE direto: ~1-5ms. Imperceptível para o usuário. O gargalo é sempre o tempo de resposta da API LLM (tipicamente 50-500ms por chunk), não o broadcast interno.

Se Lanttern escalar para múltiplos nodes, PubSub funciona entre nodes via `Phoenix.PubSub` com adapter distribuído (ex: `Phoenix.PubSub.PG2`, já configurado). Sem mudanças de código.

### P: Como lidamos com tool calls durante streaming? O LLM pausa, chama uma tool e retoma.

Durante streaming, o fluxo é:

1. LLM faz stream de tokens de texto → broadcast como eventos `:chunk`
2. LLM emite um tool call → broadcast como `:tool_call_start`
3. Worker pausa o stream, executa a tool
4. Broadcast `:tool_call_result` com o resultado
5. Alimenta o resultado de volta ao LLM → streaming retoma do passo 1

O ConversationComponent lida com isso mostrando:
- Texto em streaming conforme chega (`:chunk`)
- Um indicador "chamando tool..." quando `:tool_call_start` é recebido
- O resultado da tool (ex: card de aula) quando `:tool_call_result` é recebido
- Texto em streaming continuando após o tool call completar

É um processo sequencial — o worker gerencia o lifecycle do stream. O component apenas reage aos eventos.

### P: E se o usuário navegar para fora durante streaming? Tokens são perdidos?

Quando o usuário navega para fora, o processo LiveView termina e se desinscreve do PubSub. O worker (Oban job ou Task) continua até completar independentemente — ele não sabe nem se importa com o subscriber.

A mensagem completa é persistida no banco de dados quando o stream termina (evento `:message_complete`). Quando o usuário volta para a conversa, todas as mensagens (incluindo a que estava em streaming) são carregadas do banco. Nenhum dado é perdido.

Mensagens parciais (o buffer de streaming) são perdidas da UI mas não da conversa. O banco de dados é a fonte de verdade, não o estado do LiveView.

---

## 5. Memória do Usuário

### P: Como prevenimos o sistema de memória de injetar informações obsoletas ou erradas?

Três salvaguardas:

1. **Score de relevância**: Memórias têm um `relevance_score` (0.0-1.0). O prompt de sumarização instrui o LLM a atribuir scores mais baixos a informações sensíveis ao tempo. Apenas as top N memórias (por score) são injetadas.

2. **Expiração**: Memórias com tempo limitado têm campo `expires_at`. Um cron job faz prune de entradas expiradas. Exemplo: "O usuário está trabalhando em uma unidade de frações" expira após 30 dias.

3. **Controle manual**: Staff pode visualizar e deletar suas próprias memórias via página de configurações. Se o agente disser algo errado baseado em uma memória, o usuário pode corrigir diretamente.

Adicionalmente, memórias são injetadas como contexto, não como fatos. O wrapper do system prompt deixa isso claro:

```xml
<user_memory>
  <note>O seguinte é um resumo de interações anteriores. Pode estar desatualizado.
  Use como contexto, não como verdade absoluta. Se o usuário contradisser uma memória,
  confie no usuário.</note>
  <preferences>Usuário prefere planos de aula detalhados com notas de diferenciação</preferences>
</user_memory>
```

### P: A chamada LLM de sumarização não vai adicionar custo para cada conversa?

Sim, mas é uma única e pequena chamada LLM por encerramento de conversa — não por mensagem. A entrada é a transcrição da conversa (tipicamente 5-20 mensagens), e a saída são 2-3 frases de resumo compactas. Estimativa de custo:

- Entrada: ~2.000 tokens (transcrição da conversa)
- Saída: ~200 tokens (resumo)
- Modelo: Pode usar um modelo mais barato/menor (ex: GPT-4o-mini)
- Custo por sumarização: ~$0,001

Para uma escola com 50 professores ativos, cada um tendo 5 conversas por semana: 250 sumarizações × $0,001 = **$0,25/semana**. Insignificante.

### P: Qual a diferença entre memória do usuário e contexto de conversa?

| Aspecto | Memória do Usuário | Contexto de Conversa |
|---|---|---|
| **Escopo** | Entre conversas, por-usuário | Conversa única, por-entidade |
| **Persistência** | Sobrevive após fim da conversa | Atrelado ao lifecycle da conversa |
| **Conteúdo** | Resumos de interações passadas, preferências | Dados curriculares (detalhes de strand, lesson, ILP) |
| **Fonte** | Gerado por AI a partir de conversas | Carregado de entidades no banco |
| **Layer** | Layer 0 (antes de config da escola) | Layer 5 (contexto curricular) |
| **Exemplo** | "Usuário prefere atividades práticas" | "Strand: Introdução a Frações, Ano 4" |

Memória diz ao agente **quem** o usuário é. Contexto diz ao agente **sobre o que** a conversa trata.

### P: Memórias podem ser compartilhadas entre escolas se um professor trabalha em múltiplas escolas?

Não. Memórias são scoped para `(profile_id, school_id)`. Um professor na Escola A e Escola B tem conjuntos de memória separados. Isso é intencional:

1. **Isolamento de dados**: Escolas são donas dos seus dados. Uma memória gerada do currículo da Escola A não deve vazar para a Escola B.
2. **Relevância**: O contexto de ensino varia por escola. "Prefere planos de aula em português" pode ser relevante em uma escola mas não em outra.
3. **Padrão de Scope**: Isso segue o padrão `Scope` de autorização existente no Lanttern — todos os dados school-scoped são isolados por `school_id`.

---

## 6. Contexto Universal de Conversas

### P: Por que uma tabela polimórfica ao invés de uma tabela de junção separada por tipo de contexto?

Uma tabela de junção separada por tipo (como a atual `strand_agent_conversations`) requer:
- Uma nova migration para cada novo tipo de contexto
- Um novo schema Ecto para cada tabela de junção
- Novas funções de query no módulo de contexto
- Lógica condicional para checar múltiplas tabelas ao carregar contextos de conversa

A tabela polimórfica requer:
- Uma migration (feita uma vez)
- Um schema Ecto
- Uma query para carregar todos os contextos de uma conversa
- Uma nova cláusula de função por tipo de contexto (no `ContextResolver`)

A abordagem polimórfica escala com o número de tipos de entidade sem mudanças de schema. Adicionar contexto de "assessment" ou "student" é uma mudança de código, não de banco.

**Trade-off**: Perdemos integridade referencial de foreign key no nível do banco para `context_id`. Isso é aceitável porque:
1. Context links são criados programaticamente (não via input do usuário), então referências inválidas são erros de programador, não erros de usuário
2. O `ContextResolver` valida que a entidade existe ao resolver — uma referência pendente produz um soft error (contexto não carregado), não um crash
3. Esse padrão é bem estabelecido em Elixir/Ecto (ex: embeds polimórficos, Activity streams)

### P: O que acontece com a tabela antiga `strand_agent_conversations`?

Conforme regra 7 do CLAUDE.md (padrão é dívida técnica, não refatoração):

1. Os dados são **migrados** para `conversation_contexts` (uma linha por strand, opcionalmente uma por lesson)
2. A tabela antiga é **deixada como está** — não é dropada, não é modificada
3. Código novo usa `conversation_contexts` exclusivamente
4. Código antigo que lê `strand_agent_conversations` continua funcionando (até eventualmente ser limpo)

Não há breaking change. A tabela antiga se torna dívida técnica não utilizada, limpa em um sprint futuro.

### P: Como funciona o `context_metadata` JSONB? Quando é útil?

`context_metadata` armazena um **snapshot** dos dados relevantes da entidade no momento em que a conversa foi criada. Dois casos de uso:

1. **Auditoria**: Após a conversa, podemos ver exatamente o que o agente sabia. Se os itens curriculares de um strand mudaram, o metadata mostra a versão que o agente viu.

2. **Deleção de entidade**: Se uma lesson é deletada após uma conversa sobre ela, o metadata preserva o nome e detalhes da lesson para contexto histórico.

O metadata é opcional. Na maioria dos casos, o `ContextResolver` carrega a entidade ao vivo do banco. O metadata é uma rede de segurança, não uma fonte primária de dados.

### P: Uma única conversa pode ter contextos de escolas diferentes?

Não. Conversas são scoped para `school_id` (via `agent_conversations.school_id`). Todas as entidades de contexto devem pertencer à mesma escola. O `ContextResolver` garante isso:

```elixir
def register_context(%Scope{school_id: school_id}, conversation, context_type, context_id) do
  entity = load_entity(context_type, context_id)
  true = entity.school_id == school_id
  # ... criar conversation_context
end
```

Isso segue o padrão `Scope` — isolamento de escola é garantido em cada fronteira.

---

## 7. Observabilidade

### P: Por que não começar com Langfuse desde o dia um? Por que a abordagem faseada?

Três razões:

1. **Otimização prematura**: Nas Phases 1-2, estamos consolidando bibliotecas e construindo abstrações. O volume de chamadas LLM é baixo (POC com usuários limitados). A tabela `llm_calls` existente + eventos `:telemetry` são suficientes. Adicionar infraestrutura Langfuse antes de precisar é overhead.

2. **Clareza de integração**: Na Phase 3, o módulo `AgentChat.LLM` está estável e sabemos exatamente o que instrumentar. Integrar Langfuse com um módulo que ainda está sendo refatorado (Phase 1) significaria atualizar a integração conforme o código muda.

3. **Validação de custo**: Começar com Langfuse Cloud (tier gratuito) nos permite validar o valor antes de comprometer com infraestrutura self-hosted. Se o time não olha os dashboards, sabemos para não investir em self-hosting.

### P: Podemos pular Langfuse Cloud e ir direto para self-hosted?

Sim, mas não é recomendado. Langfuse self-hosted requer:

- Cluster Kubernetes (ou Docker Compose, mas sem HA)
- Instância ClickHouse (o maior peso operacional)
- Instância PostgreSQL (pode reutilizar existente)
- Instância Redis
- Storage compatível com S3
- Tempo de DevOps para setup, manutenção, upgrades

O tier Cloud começa em **$0/mês** (50k traces). Para um time validando a ferramenta, o tier gratuito elimina todo overhead de infraestrutura. Graduem para self-hosted quando:

- Volume de traces exceder 5M/mês (Cloud Pro a $199/mês começa a ficar caro)
- Requisitos de residência de dados mandarem on-premises
- O time estiver confiante que Langfuse é a ferramenta certa (validado no Cloud)

### P: E usar o dashboard nativo da OpenAI para observabilidade?

O dashboard da OpenAI mostra uso de API e custos, que é útil mas limitado:

1. **Sem tracing**: Você não vê o lifecycle completo da conversa (construção de prompt → chamada LLM → execução de tool → resposta)
2. **Sem avaliação**: Sem LLM-as-judge, sem labeling manual, sem testes de regressão
3. **Sem gestão de prompts**: Prompts vivem no seu código, não na plataforma da OpenAI
4. **Vendor lock-in**: Se trocar para Anthropic ou Google, perde toda observabilidade
5. **Sem views por-escola**: OpenAI mostra uso agregado, não breakdowns por-escola

O dashboard da OpenAI é um complemento, não um substituto, para observabilidade LLM adequada.

---

## 8. Migração e Rollback

### P: Qual é o plano de rollback se a migração para ReqLLM quebrar algo em produção?

A migração está atrás de fronteiras de módulos limpas. Opções de rollback:

1. **Git revert**: As mudanças estão em 2 arquivos (`agent_chat.ex`, `chat_response_worker.ex`) + 1 novo módulo (`agent_chat/llm.ex`). Reverter para a versão LangChain é um `git revert` do commit de migração.

2. **Feature flag**: Podemos introduzir uma feature flag temporária que alterna entre o path antigo LangChain e o novo path ReqLLM. Isso é overkill para uma mudança de 2 arquivos mas disponível se o time quiser.

3. **LangChain permanece no mix.exs até Phase 1 ser verificada**: Podemos manter `{:langchain, "0.4.0"}` nas deps até verificarmos o path ReqLLM em staging. Remover apenas após confiança.

O ponto chave: o schema do banco de dados não muda na Phase 1. Todas as mensagens, conversas e model calls são armazenadas no mesmo formato. A migração é puramente na camada de código — totalmente reversível.

### P: Como migramos os dados de `strand_agent_conversations` sem downtime?

A migração é aditiva:

1. Deploy da tabela `conversation_contexts` (nova tabela, sem impacto no existente)
2. Executar migração de dados que copia linhas de `strand_agent_conversations` para `conversation_contexts`
3. Deploy do código que lê de `conversation_contexts`
4. Código antigo que lê `strand_agent_conversations` continua funcionando (os dados ainda estão lá)

Não há downtime porque:
- Passo 1 é uma nova tabela (zero impacto)
- Passo 2 é uma migração background (pode rodar em horários de baixo tráfego)
- Passo 3 deploya código novo que lê a nova tabela
- A tabela antiga nunca é dropada ou modificada

Se o código novo tiver bug, revertemos o deploy. O código antigo ainda lê a tabela antiga. Sem perda de dados.

### P: E se uma migração entre fases falhar? Podemos rodar Phase 3 sem Phase 2?

Não. As fases são dependências sequenciais:

- **Phase 1** (abstração LLM) é necessária por todas as fases subsequentes — todas usam `AgentChat.LLM`
- **Phase 2** (contexto + mensagens ricas) é necessária pela Phase 3 — injeção de memória usa o pipeline de resolução de contexto
- **Phase 3** (memória) é independente da Phase 4 — streaming não precisa de memória
- **Phase 4** (streaming) é independente da Phase 5 — file uploads não precisam de streaming

Então a cadeia de dependências é: 1 → 2 → 3, e 1 → 4, e 1 → 5. Phases 3, 4 e 5 são independentes entre si (após Phase 2 para 3, após Phase 1 para 4 e 5).

---

## 9. Testes

### P: Como testamos o módulo `AgentChat.LLM` sem fazer chamadas reais à API?

O mesmo padrão já usado para revisões de ILP — injeção de dependência:

```elixir
# Produção: usa ReqLLM
AgentChat.LLM.run_completion(model, messages, tools)

# Teste: injeta módulo stub
AgentChat.LLM.run_completion(model, messages, tools, llm_module: Lanttern.ReqLLMStub)
```

O `ReqLLMStub` já existe em `test/support/stubs/req_llm.ex`. Estendemos para lidar com tool calling:

```elixir
defmodule Lanttern.ReqLLMStub do
  def generate_text(_model, _context, opts \\ []) do
    case Keyword.get(opts, :stub_response, :text) do
      :text ->
        {:ok, %ReqLLM.Response{message: text_message("Resposta stub")}}
      :tool_call ->
        {:ok, %ReqLLM.Response{message: tool_call_message("create_lesson", %{...})}}
    end
  end
end
```

Isso permite testar o pipeline completo (construção de mensagem → chamada LLM → extração de resposta → execução de tool) sem chamadas reais à API.

### P: Como testamos streaming?

Testes de streaming usam um stub que emite chunks:

```elixir
defmodule Lanttern.ReqLLMStreamStub do
  def stream_text(_model, _context, callback, _opts \\ []) do
    callback.({:chunk, "Olá "})
    callback.({:chunk, "mundo"})
    callback.({:done, %{usage: %{input: 10, output: 5}}})
    :ok
  end
end
```

O teste se inscreve no PubSub, envia uma mensagem, e asserta que eventos `:chunk` chegam em ordem, seguidos por `:message_complete`.

### P: Como testamos a sumarização de memória? Ela chama o LLM.

O `MemorySummaryWorker` aceita um módulo LLM via injeção de dependência (mesmo padrão). O stub de teste retorna um resumo predeterminado:

```elixir
test "resume conversa em entradas de memória" do
  conversation = insert(:agent_conversation, ...)
  insert(:agent_message, conversation: conversation, role: "user", content: "Prefiro atividades práticas")
  insert(:agent_message, conversation: conversation, role: "assistant", content: "Anotado! Vou sugerir...")

  perform_job(MemorySummaryWorker, %{conversation_id: conversation.id}, llm_module: SummaryStub)

  memories = AgentChat.Memory.list_user_memories(scope, profile)
  assert length(memories) == 1
  assert hd(memories).summary =~ "práticas"
end
```

---

## 10. Performance e Custos

### P: Quanto esta arquitetura vai custar em taxas de API LLM?

Custo depende do volume de uso. Estimativas para uma escola com 50 professores ativos:

| Operação | Tokens/chamada | Chamadas/semana | Custo/semana (GPT-4o) | Custo/semana (GPT-4o-mini) |
|---|---|---|---|---|
| Mensagem chat (com contexto) | ~3.000 in + ~1.000 out | 500 | ~$5,00 | ~$0,15 |
| Sumarização de memória | ~2.000 in + ~200 out | 50 | ~$0,50 | ~$0,02 |
| Renomeação de conversa | ~500 in + ~50 out | 50 | ~$0,05 | ~$0,002 |
| **Total** | | | **~$5,55/semana** | **~$0,17/semana** |

Usar GPT-4o-mini para sumarização e rename (não visível ao usuário) reduz custos significativamente. O `base_model` da escola controla o modelo principal do chat.

Phase 4 adiciona **enforcement de orçamento**: escolas podem definir `monthly_token_budget` em `school_ai_configs`. O worker verifica o orçamento antes de fazer uma chamada LLM e retorna erro se exceder.

### P: A injeção de memória vai aumentar custos de token significativamente?

Injeção de memória adiciona ~200-500 tokens por conversa (a camada de resumo). Para uma conversa com 3.000 tokens de contexto já (strand + lesson + config escola), memórias adicionam ~10-15% de overhead. Isso é insignificante comparado ao valor de respostas personalizadas.

O cap (top 10 memórias) previne crescimento ilimitado. Se um usuário tem 100 memórias, apenas as 10 mais relevantes são injetadas.

### P: Qual o impacto de performance da tabela polimórfica de contexto?

A tabela `conversation_contexts` tem:
- Um índice único em `(conversation_id, context_type, context_id)`
- Um índice em `(context_type, context_id)`

Carregar contextos para uma conversa é uma única query:

```sql
SELECT * FROM conversation_contexts WHERE conversation_id = $1;
```

Isso retorna 1-3 linhas (strand, lesson, talvez ILP). A query bate no índice diretamente. Performance é idêntica à query atual de `strand_agent_conversations` — um lookup indexado retornando um punhado de linhas.

---

## 11. Segurança e Propriedade de Dados

### P: Se adotarmos Langfuse Cloud, estamos enviando dados de conversa para terceiros?

Sim. Langfuse Cloud recebe traces, que podem incluir conteúdo de prompt, conteúdo de completion e contagem de tokens. Porém:

1. **GDPR compliant**: Langfuse oferece residência de dados na EU e DPA (Data Processing Agreement)
2. **SOC 2 Type II certificado**: Compliance de segurança padrão
3. **Mascaramento de dados**: Você pode mascarar campos sensíveis antes de enviar traces
4. **Conteúdo opt-in**: Você controla quais dados são incluídos nos traces. Pode enviar apenas metadata (modelo, tokens, latência) sem conteúdo real de mensagem.

Para máximo controle de dados, Langfuse self-hosted mantém tudo na sua infraestrutura. A abordagem faseada (Cloud → self-hosted) permite começar com conveniência e migrar para controle quando necessário.

### P: Como protegemos o endpoint SSE (Phase 5) para o Vercel AI SDK?

O endpoint SSE precisa de segurança separada porque não é uma rota LiveView (sem WebSocket, sem CSRF token):

1. **Autenticação por sessão**: O React island compartilha a mesma sessão de browser que a página LiveView. O endpoint SSE valida o cookie de sessão.
2. **Proteção CSRF**: Usar um token CSRF passado do LiveView para o React island como prop. O componente React inclui no header do request SSE.
3. **Rate limiting**: Aplicar middleware de rate limiting por-usuário (plug) no endpoint SSE.
4. **Autorização por Scope**: O endpoint verifica `Scope.has_permission?(scope, "agents_management")` antes de processar.

```elixir
# router.ex
pipeline :api_auth do
  plug :fetch_session
  plug :verify_session_user
  plug :verify_csrf_header  # Plug customizado: verifica header X-CSRF-Token
  plug :rate_limit, max: 10, window: 60_000  # 10 requests/minuto
end

scope "/api" do
  pipe_through [:api_auth]
  post "/chat", AiStreamController, :stream
end
```

### P: E a propriedade de dados com ReqLLM? Chamadas de API são logadas pelos provedores?

Quando ReqLLM chama a API da OpenAI, a OpenAI processa o request conforme seus termos de API. Especificamente:

1. **OpenAI não treina com dados de API** (conforme política atual)
2. **OpenAI retém dados de API por 30 dias** para monitoramento de abuso (a menos que você opte por sair via configurações de retenção de dados da API)
3. **Lanttern armazena todos os dados de conversa** em seu próprio banco — temos uma cópia local completa

O mesmo se aplica a qualquer provedor (Anthropic, Google, etc.). A arquitetura armazena todos os dados localmente; o provedor recebe uma cópia durante a chamada de API. Para máximo controle, escolas podem configurar modelos locais/privados (via suporte de provedores do ReqLLM) quando estiverem disponíveis.

---

## 12. Timeline e Priorização

### P: Podemos pular fases ou fazê-las em paralelo?

**Oportunidades de paralelismo:**
- Phase 3 (Memória) e Phase 4 (Streaming) são independentes após Phase 2. Podem rodar em paralelo se o time tiver capacidade.
- Phase 5 (File uploads + React) é independente após Phase 1.

**Não podem ser puladas:**
- Phase 1 (abstração LLM) é fundamental — tudo depende dela
- Phase 2 (Contexto) é necessária pela Phase 3 (Memória usa o pipeline de contexto)

**Podem ser adiadas:**
- Phase 4 (Streaming) — melhoria de UX legal mas não bloqueante
- Phase 5 (React + File uploads) — depende do progresso do setup React

### P: E se o setup React estiver pronto antes da Phase 5? Podemos antecipar?

Sim. O React island de chat (Phase 5, Passos 5.3-5.4) pode ser movido para Phase 4 ou até Phase 3 se:

1. Infraestrutura de React islands estiver funcionando
2. A abstração `AgentChat.LLM` estiver estável (Phase 1 completa)
3. O endpoint SSE puder ser construído rapidamente (é uma camada fina de tradução sobre PubSub)

O backend não muda — apenas o path frontend é adicionado. Este é o benefício da arquitetura UI-agnostic.

### P: 2 semanas por fase é realista?

Cada fase é scoped para um conjunto específico e delimitado de mudanças:

- **Phase 1**: 2 arquivos reescritos + 1 novo módulo + updates de testes. 2 semanas é confortável.
- **Phase 2**: 1 migration + 1 novo módulo + mudanças de componente. 2 semanas é apertado mas factível.
- **Phase 3**: 1 migration + 1 novo módulo + 1 Oban worker + página UI. 2 semanas é apertado. Pode estender para 3.
- **Phase 4**: Streaming (novo path no worker + componente) + tracking de custo. 2 semanas é apertado. Pode estender para 3.
- **Phase 5**: Múltiplas features independentes. Esperado levar 3-4 semanas.

As estimativas são otimistas-mas-alcançáveis. Buffer deve ser adicionado para testes de integração e problemas inesperados.

---

## 13. Detalhes do Vercel AI SDK

### P: Como o Vercel Data Stream Protocol realmente funciona?

É um protocolo SSE (Server-Sent Events) onde cada evento é uma linha única com prefixo de tipo:

```
0:"Hello "          → chunk de texto "Hello "
0:"world"           → chunk de texto "world"
9:{"toolCallId":"1","toolName":"create_lesson","args":{"description":"..."}}
a:{"toolCallId":"1","result":{"lesson_id":42}}
e:{"finishReason":"stop","usage":{"promptTokens":150,"completionTokens":50}}
d:{"finishReason":"stop"}
```

Códigos de tipo:
- `0` = token de texto
- `9` = tool call
- `a` = resultado de tool
- `e` = finish com metadata
- `d` = sinal de done

O controller Phoenix precisa produzir exatamente este formato. É um exercício de concatenação de strings — não complexo, apenas preciso.

### P: useChat funciona com respostas não-streaming (batch)?

Sim. `useChat` também suporta respostas não-streaming. Se o backend retorna a mensagem completa de uma vez (ao invés de streaming), `useChat` ainda lida corretamente — simplesmente aparece tudo de uma vez ao invés de token-by-token.

Isso significa que podemos adotar o React island antes de implementar streaming. O endpoint SSE pode retornar uma única mensagem completa (como nosso fluxo batch atual), e `useChat` vai exibi-la.

### P: O que acontece se a conexão SSE cair no meio do stream?

`useChat` lida com reconexão automaticamente. Quando a conexão cai:

1. A mensagem parcial atual é preservada no estado do componente
2. O hook tenta reconectar (comportamento de retry configurável)
3. Se a reconexão falhar, a mensagem é marcada como incompleta

O backend lida com isso verificando se o job Oban já completou. Se o worker terminou e persistiu a mensagem, o client reconectado carrega a mensagem completa do banco (via chamada API ou bridge LiveView).

---

## 14. Detalhes do Langfuse

### P: Como a integração OpenTelemetry funciona com Elixir especificamente?

O ecossistema Elixir/BEAM tem forte suporte a OpenTelemetry via pacotes hex `opentelemetry`:

```elixir
# mix.exs
{:opentelemetry, "~> 1.4"},
{:opentelemetry_api, "~> 1.3"},
{:opentelemetry_exporter, "~> 1.7"}
```

Configuração para exportar para Langfuse:

```elixir
# config/runtime.exs
config :opentelemetry, :resource, service: %{name: "lanttern"}
config :opentelemetry,
  span_processor: :batch,
  exporter: {:opentelemetry_exporter, %{
    endpoints: ["https://seu-langfuse.com/api/public/otel"],
    headers: [{"Authorization", "Bearer #{langfuse_api_key}"}]
  }}
```

Então no código:

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

O endpoint OTLP do Langfuse recebe esses spans e os exibe no visualizador de traces.

### P: Podemos usar Langfuse para gestão de prompts ao invés de manter prompts no código?

Sim, mas é uma consideração Phase 5+. A gestão de prompts do Langfuse permite:

1. **Versionamento**: Manter múltiplas versões de um prompt, deployar versões específicas
2. **Playground**: Testar prompts contra diferentes modelos diretamente na UI do Langfuse
3. **Caching**: Caching server-side + client-side para evitar carregar prompts em cada chamada
4. **Iteração não-developer**: Educadores ou product managers podem ajustar prompts sem mudanças de código

O trade-off é que prompts saem de código versionado para um serviço externo. Isso adiciona uma dependência runtime (Langfuse precisa estar disponível para carregar prompts) e reduz visibilidade no nível de código.

A recomendação é: manter prompts no código por enquanto (Phase 1-3). Avaliar gestão de prompts do Langfuse na Phase 5 quando a infraestrutura de observabilidade estiver madura e o time tiver experiência com a plataforma.

### P: E as features de avaliação do Langfuse? Como usaríamos?

A avaliação do Langfuse permite verificações automatizadas de qualidade nos outputs de AI. Exemplos práticos para o Lanttern:

1. **LLM-as-judge**: Após um plano de aula ser gerado, uma chamada LLM separada o avalia contra rubricas (ex: "O plano inclui diferenciação?", "É apropriado para a faixa etária?"). O score é armazenado no Langfuse.

2. **Feedback de usuário**: Quando um professor marca um plano de aula como "útil" ou "não útil", esse feedback é enviado ao Langfuse como score atrelado ao trace. Com o tempo, isso constrói um dataset para medir tendências de qualidade.

3. **Testes de regressão**: Quando prompts mudam, executar o mesmo conjunto de conversas de teste pelo novo prompt e comparar scores contra o prompt antigo. Isso previne regressões de qualidade.

Essas são features Phase 3+. Requerem que a infraestrutura de tracing esteja em funcionamento primeiro.

---

## 15. Ecossistema Jido

### P: Você mencionou que Jido pode ser reconsiderado no futuro. Quando especificamente?

Jido se torna relevante quando o Lanttern precisar de:

1. **Múltiplos agentes independentes** que coordenam entre si (ex: um agente "planejador de aulas" que delega para um agente "pesquisador de currículo" e um agente "designer de avaliações")
2. **State machines complexas** onde o comportamento do agente muda baseado em estado acumulado (além do que um banco de dados pode representar eficientemente)
3. **Colaboração de agentes em tempo real** onde múltiplos agentes trabalham na mesma tarefa concorrentemente e precisam compartilhar resultados intermediários

Atualmente, Lanttern tem um tipo de agente (planejador de aulas) com um lifecycle simples (receber mensagem → pensar → responder/agir). Oban lida com isso perfeitamente.

Se o roadmap de 2026 evoluir para sistemas multi-agent, revisitar Jido nesse ponto. A abstração `AgentChat.LLM` torna isso possível — Jido substituiria a camada de worker, não a camada de client LLM.

### P: E o `jido_action` para tools tipadas? Parece melhor que o que estamos propondo.

`jido_action` fornece validação de schema em tempo de compilação para definições de tools e conversão automática para o formato de tool do LLM. É genuinamente melhor que specs de tool escritas à mão.

Porém, Lanttern atualmente tem exatamente **2 tools** (create_lesson, update_lesson) com uma terceira planejada (set_conversation_title). O overhead de um framework para 3 tools não se justifica.

Quando a contagem de tools crescer (10+), a validação em tempo de compilação e auto-conversão se tornam valiosas. Nesse ponto, `jido_action` pode ser adotado dentro de `AgentChat.Tools` sem mudar nada fora desse módulo.

### P: Existe risco de o ecossistema Jido se tornar o padrão Elixir e nós ficarmos de fora?

Jido é promissor mas novo (v2.0 lançada recentemente). O ecossistema de AI em Elixir não tem um "padrão" ainda — é cedo demais. Ao escolher ReqLLM (parte do ecossistema Jido) para o client LLM, já estamos nos beneficiando do melhor componente do ecossistema.

Se Jido se tornar o padrão, adotá-lo depois é direto porque:
1. ReqLLM (já adotado) é a fundação da camada LLM do Jido
2. `AgentChat.LLM` abstrai a orquestração — substituí-la pela orquestração do Jido é uma mudança delimitada
3. O schema de banco de dados, padrões PubSub e camada UI são Jido-agnostic

Estamos fazendo uma aposta pragmática: adotar as partes comprovadas (ReqLLM) e adiar as partes não comprovadas (Jido agents) até estarem battle-tested e precisarmos delas.

---

## 16. Monolith vs Microservice

### P: Vamos ser honestos — Python não tem ferramentas de AI muito melhores? Por que estamos nos limitando a Elixir?

Sim, o ecossistema de AI do Python é objetivamente mais rico. Aqui está o que perdemos ficando em Elixir:

| Categoria | O que Python tem | O que Elixir tem | Severidade do gap |
|---|---|---|---|
| **Orquestração de agents** | LangGraph (stateful, checkpointing, time-travel, 5 modos de streaming) | Custom tool_call_loop (~25 linhas) | **Grande** |
| **Multi-agent** | CrewAI, AG2/AutoGen, Swarm | Nada production-ready | **Grande** |
| **RAG/Documentos** | LlamaIndex (loaders, chunking, retrieval pipelines) | Implementação manual | **Grande** |
| **Avaliação** | DeepEval, RAGAS, PromptFoo | Nada | **Grande** |
| **Structured output** | Instructor (3M+ downloads), Pydantic AI | Validação Ecto (manual) | **Médio** |
| **SDKs de provedores** | Oficial de OpenAI, Anthropic, Google | ReqLLM (community, bom mas não oficial) | **Pequeno-Médio** |
| **Memória** | mem0, MemGPT/Letta | Implementação custom | **Médio** |
| **Observabilidade** | SDKs nativos Langfuse/LangSmith | OpenTelemetry (funciona, não nativo) | **Pequeno-Médio** |

Os gaps são reais. A questão é: **precisamos dessas capabilities hoje, e o custo de um microserviço vale o acesso?**

Para as necessidades atuais do Lanttern (client LLM, tool calling, memória básica, streaming), Elixir + ReqLLM é suficiente. Os gaps que mais importam (orquestração LangGraph, avaliação DeepEval) são necessidades futuras, não bloqueantes.

### P: Como seria a arquitetura de um sidecar Python na prática?

Um serviço FastAPI co-deployed junto com Phoenix, compartilhando PostgreSQL e Redis:

```
Prompt do usuário → Phoenix LiveView → POST http://localhost:8000/chat
                                              │
                                              ▼
                                        FastAPI (Python)
                                        │ 1. GET contexto do Phoenix
                                        │ 2. Rodar agente LangGraph
                                        │ 3. Em tool call → POST para API interna do Phoenix
                                        │ 4. Em chunk → publicar no Redis
                                        │ 5. Ao completar → POST mensagem para Phoenix
                                              │
                                              ▼
                                        Redis (bridge PubSub)
                                              │
                                              ▼
                                        Phoenix PubSub → LiveView update
```

O sidecar cuida da orquestração LLM. Phoenix mantém toda lógica de domínio (Scope, Ecto, regras de negócio, execução de tools). Comunicação é HTTP localhost (~5-10ms de overhead).

### P: Se contratarmos um engenheiro Python de AI, como ele trabalharia com o codebase Elixir?

Ele não precisaria tocar em Elixir. O padrão sidecar cria uma fronteira limpa:

- **Engenheiro Python cuida de**: Serviço FastAPI, agentes LangGraph, pipelines de avaliação, otimização de memória, RAG se necessário
- **Time Elixir cuida de**: Phoenix, LiveView, lógica de negócio, Scope/auth, banco, endpoints de execução de tools
- **Contrato compartilhado**: API HTTP interna entre os dois serviços (documentada, versionada)

O engenheiro Python deploya seu serviço junto com Phoenix. Ele consome APIs internas que o time Elixir expõe. Sem necessidade de code reviews cross-language.

### P: Como tool calls (create_lesson) funcionariam cruzando a fronteira de serviço?

Quando o agente LangGraph decide chamar `create_lesson`, o fluxo é:

1. LangGraph emite um tool call: `{"name": "create_lesson", "args": {"description": "...", "moment_id": 1}}`
2. FastAPI recebe o tool call e encaminha para Phoenix: `POST http://localhost:4000/internal/tools/create_lesson`
3. Phoenix recebe o request, valida o scope token, chama `Lessons.create_lesson/3` com autorização e audit logging adequados
4. Phoenix retorna o resultado: `{"lesson_id": 42, "status": "ok"}`
5. FastAPI alimenta o resultado de volta ao LangGraph, que continua a conversa

O ponto crítico: **Phoenix continua dono da execução de tools**. O microserviço nunca toca lógica de negócio diretamente. Isso preserva autorização Scope, audit logging e integridade de dados.

### P: Qual o impacto real de latência?

| Arquitetura | Prompt até primeiro token | Round-trip de tool call | Total para troca típica |
|---|---|---|---|
| **Monolith Elixir** | Apenas latência da API LLM (~500ms) | 0ms (in-process) | ~2-5 segundos |
| **Sidecar Python** | +5-10ms (hop localhost) | +10-20ms (dois hops localhost) | ~2-5,1 segundos |
| **Microserviço completo** | +25-50ms (hop de rede) | +50-100ms (dois hops de rede) | ~2-5,3 segundos |

Para uma interface de chat onde a própria API LLM leva 2-5 segundos por resposta, o overhead do sidecar (5-10ms) é imperceptível. O overhead do microserviço completo (25-50ms) é perceptível apenas durante streaming (entrega de tokens irregular).

### P: TypeScript não seria mais natural já que vamos adicionar React?

TypeScript tem vantagens para a camada frontend (Vercel AI SDK é nativo), mas para o backend de AI:

- O ecossistema AI do TypeScript é um **subconjunto do Python**. LangChain.js e LangGraph.js existem mas têm comunidades menores. CrewAI, LlamaIndex, DeepEval, RAGAS, Instructor — todos exclusivos Python.
- A força do TypeScript é frontend, não orquestração de AI.
- Se estamos adicionando um serviço para orquestração AI, Python dá acesso a 10x mais ferramentas.

Se contratarmos um engenheiro de AI, quase certamente saberá Python, não TypeScript. TypeScript é a escolha certa para a UI de chat (React + Vercel AI SDK). Python é a escolha certa para orquestração AI (se precisarmos de serviço separado).

### P: Qual o custo operacional real de manter dois serviços?

| Dimensão | Monolith | Sidecar | Microserviço completo |
|---|---|---|---|
| **Infra mensal** | ~$5K | ~$5,5-6,5K | ~$18-30K |
| **Pipelines CI/CD** | 1 | 1 (co-deployed) | 2 (separados) |
| **Complexidade on-call** | Baixa | Baixa (mesmo host) | Média (debug cross-service) |
| **Testes integração** | Padrão | Precisam testes cross-service | Precisam contract tests + E2E |
| **Gestão de config** | 1 set de env vars | 2 sets, secrets compartilhados | 2 sets, auth de rede, service discovery |

O sidecar é o sweet spot: 90% dos benefícios do ecossistema Python com apenas 10% do custo operacional de microserviço. Mesmo deployment unit, mesmo host, banco compartilhado.

### P: E se precisarmos de RAG para documentos curriculares (PDFs, livros)?

Este é um dos argumentos mais fortes para um sidecar Python. LlamaIndex fornece:

- **Document loaders**: PDF, DOCX, HTML, Google Docs — 100+ formatos
- **Estratégias de chunking**: Semântico, baseado em sentenças, recursivo — otimizado para conteúdo educacional
- **Modelos de embedding**: OpenAI, Cohere, modelos locais
- **Vector stores**: pgvector, Pinecone, Qdrant — integrações first-class
- **Pipelines de retrieval**: Busca híbrida, re-ranking, transformação de query

Construir funcionalidade equivalente em Elixir exigiria escrever parsers de documentos customizados, algoritmos de chunking e integrações de busca vetorial — semanas de trabalho que LlamaIndex fornece pronto.

Se RAG sobre documentos curriculares se tornar um requisito, isso sozinho justifica um sidecar Python.

### P: LangGraph é realmente muito melhor que nosso tool_call_loop customizado?

Para o que Lanttern faz hoje (request simples → tool call → resposta), nosso loop de 25 linhas é ok. Mas LangGraph fornece capabilities que não conseguimos replicar facilmente:

| Feature | Nosso tool_call_loop | LangGraph |
|---|---|---|
| Tool calling básico | Sim | Sim |
| Tool calls multi-turn | Sim (com max_iterations) | Sim (built-in) |
| **Checkpointing** | Não | Sim — salvar/retomar estado do agente em qualquer ponto |
| **Time-travel debugging** | Não | Sim — reproduzir conversas de qualquer checkpoint |
| **Human-in-the-loop** | Não | Sim — pausar agente, perguntar ao humano, retomar |
| **Tool calls paralelos** | Não | Sim — chamar múltiplas tools simultaneamente |
| **Modos de streaming** | 1 (token) | 5 (tokens, events, updates, messages, custom) |
| **Branching** | Não | Sim — explorar caminhos alternativos de conversa |
| **Execução durável** | Retries Oban (grosseiro) | Recuperação de estado granular mid-conversa |

Para um agente de tutoria que precisa pausar para input do professor, retomar de um estado salvo, ou explorar diferentes estratégias de explicação — LangGraph está muito à frente. Para um chatbot de planejamento de aulas, nosso loop é suficiente.

### P: O que os dados da indústria dizem sobre microserviços para AI?

Pontos-chave:

- **42% de reversão**: Uma pesquisa CNCF de 2025 encontrou que 42% das organizações que adotaram microserviços consolidaram serviços de volta em unidades maiores. Splitting prematuro é o erro mais comum.
- **Amazon Prime Video**: Migrou análise de qualidade de vídeo de microserviços para monolith de processo único, alcançando **90% de redução de custos de infraestrutura**.
- **Vercel, Notion, Stripe**: Usam AI gateways (camadas de tradução) ao invés de microserviços completos. Mantêm orquestração AI próxima da aplicação principal.
- **Tendência modular monolith**: A indústria está convergindo em monolitos modulares com fronteiras internas limpas que PODEM ser extraídas depois — exatamente o que nossa abstração `AgentChat.LLM` fornece.

O padrão que funciona: **começar monolith, extrair apenas quando houver necessidade comprovada** (escala, independência de time, ou acesso a ecossistema). Não extrair prematuramente.

### P: Qual o caminho de migração de monolith para sidecar?

O módulo `AgentChat.LLM` é o ponto de extração. Hoje ele wrappa ReqLLM. Amanhã pode wrappar uma chamada HTTP para um serviço Python:

```elixir
# Hoje (Phase 1): chamada direta ReqLLM
defp do_llm_call(model, messages, tools, opts) do
  ReqLLM.generate_text(model, context, tools: tools)
end

# Futuro (quando sidecar adotado): chamada HTTP para FastAPI
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

Nada fora de `AgentChat.LLM` muda. O módulo de contexto, workers, PubSub, UI — tudo inalterado. A extração é uma mudança de corpo de função em um módulo.

### P: Deveríamos começar com sidecar agora ao invés de ReqLLM, para evitar migração depois?

Não. Razões:

1. **Você não sabe o que precisa até construir.** Usar ReqLLM diretamente nos ensina o que a abstração LLM precisa. Extração prematura significa construir um contrato de API antes de entender os requisitos.
2. **O custo de migração é minúsculo.** Mudar um corpo de função em `AgentChat.LLM` é uma tarefa de 30 minutos. Compare com semanas de setup de sidecar antecipado.
3. **O sidecar adiciona complexidade operacional desde o dia 1.** Dois codebases, dois test suites, uma camada de bridge — tudo antes de saber se precisamos.

Construir o monolith. Aprender o que o agente realmente precisa. Extrair quando uma capability específica (LangGraph, DeepEval, RAG) exigir.

### P: DeepEval / RAGAS podem ser usados sem microserviço?

Parcialmente. Duas opções:

1. **Avaliação offline** (sem microserviço): Rodar DeepEval/RAGAS como script Python que lê dados de conversa do banco, avalia, e escreve resultados de volta. É um processo batch, não uma dependência runtime. Pode usar CI/CD ou cron job.

2. **Avaliação runtime** (precisa sidecar): Se quiser avaliação em tempo real (pontuar cada resposta AI antes de mostrar ao usuário), o framework de avaliação precisa estar no path do request — o que significa um sidecar Python.

Para o estágio atual do Lanttern, **avaliação offline é suficiente**. Rodar um batch semanal que avalia conversas recentes por qualidade, segurança e relevância. Isso requer apenas um script Python, não um sidecar completo.

---

## 17. CopilotKit vs Vercel AI SDK vs assistant-ui

### P: O que é o AG-UI Protocol e por que importa?

AG-UI (Agent-User Interaction Protocol) é um padrão aberto para comunicação agent↔frontend, adotado por Google, AWS, LangChain, Microsoft, Mastra e PydanticAI. Define tipos de evento SSE ricos (streaming de texto, tool calls, state snapshots, state deltas, eventos de lifecycle, aprovação humana) projetados especificamente para AI agents.

Importa porque o Vercel Data Stream Protocol só suporta chunks de texto e tool calls básicos. AG-UI suporta tudo que LangGraph pode emitir — state updates, workflows multi-step, aprovações human-in-the-loop. Ao usar LangGraph como backend, AG-UI é um encaixe nativo enquanto o protocolo Vercel requer uma conversão com perda.

### P: Por que CopilotKit seria melhor que Vercel AI SDK para o Lanttern?

Três features específicas do Lanttern que CopilotKit lida nativamente e Vercel AI SDK não:

1. **Aprovação do professor antes de criar aula**: O human-in-the-loop do CopilotKit pausa o agente, mostra UI de aprovação, e retoma na ação do professor. Com Vercel AI SDK, você construiria isso do zero.

2. **Indicadores de status do agente** ("Carregando contexto...", "Criando aula...", "Aguardando aprovação..."): Eventos STATE_DELTA do CopilotKit atualizam a UI em tempo real. Vercel AI SDK não tem equivalente.

3. **Rendering de lesson card**: Ambos suportam renderers customizados, mas o sistema de generative UI do CopilotKit é mais natural — o agente decide dinamicamente qual componente renderizar.

### P: Quando Vercel AI SDK ainda seria a escolha certa?

Se o Lanttern ficar no monolith Elixir (sem sidecar Python), Vercel AI SDK é mais simples:
- Sem backend LangGraph, os eventos ricos do AG-UI são irrelevantes
- O hook `useChat` é mais leve e fácil de configurar
- A comunidade é 4x maior
- Para chat básico com tool calls, Vercel AI SDK é suficiente

A regra: **Use CopilotKit se tiver LangGraph. Use Vercel AI SDK se não tiver.**

### P: E o assistant-ui? Quando é melhor que ambos?

assistant-ui é a escolha quando **customização visual importa mais que features de agent**. É headless — sem estilos default, total controle visual.

Para o Lanttern: se o time quer que o chat combine com o design existente (tema amber AI, classes `ltrn-ai-*`, componentes customizados), assistant-ui dá mais controle. Componentes do CopilotKit precisariam ser estilizados para combinar.

Porém, assistant-ui não tem state sync nem human-in-the-loop. Trade-off: **máximo controle visual** (assistant-ui) vs **máximo UX de agent** (CopilotKit).

### P: Podemos trocar entre eles depois? Quão preso ficamos?

Trocar é esforço moderado (~1-2 semanas cada direção). A arquitetura backend (`AgentChat.LLM`, `AgentChat.Tools`, Oban, PubSub) não muda em nenhum cenário. A escolha de frontend é uma decisão de camada UI, não de arquitetura.

### P: CopilotKit funciona com backend Elixir/Phoenix?

Sim, mas indiretamente. Phoenix precisaria de um controller que produz eventos SSE no formato AG-UI. Se o backend Elixir não produz state snapshots ou human-in-the-loop (porque não é LangGraph), CopilotKit funciona mas a maioria das features avançadas fica sem uso. **CopilotKit + Elixir não é recomendado** — você usaria 30% do framework.

### P: Como funciona o fluxo LangGraph → AG-UI → CopilotKit na prática?

1. Usuário digita no `<CopilotChat>`
2. CopilotKit envia via AG-UI (SSE POST) para FastAPI
3. FastAPI cria invocação LangGraph
4. LangGraph roda o grafo:
   - `RUN_STARTED` → indicador "pensando..."
   - `TEXT_MESSAGE_CONTENT` → streaming token por token
   - `TOOL_CALL_START` → UI de tool call com spinner
   - FastAPI chama Phoenix para executar tool
   - `TOOL_CALL_END` → renderiza lesson card
   - `STATE_DELTA` → atualiza status
   - `RUN_FINISHED` → estado final
5. Zero camadas de conversão — AG-UI mapeia 1:1 com eventos LangGraph

### P: AG-UI Protocol é maduro o suficiente para produção?

Introduzido em 2025, adotado por Google, AWS, Microsoft, LangChain. Spec pública em docs.ag-ui.com.

**Riscos:** Mais novo que Vercel Data Stream Protocol. CopilotKit é o implementador principal. Spec pode evoluir.

**Mitigações:** Adoção corporativa major sugere estabilidade. Padrão aberto permite implementações alternativas. CopilotKit é open source.

Para o timeline do Lanttern (Phase 4-5, vários meses à frente), AG-UI estará mais maduro quando precisarmos.
