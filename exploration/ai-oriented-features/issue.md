# What?

This project is about setting up the base for the AI agent(s) structure we'll be iterating for the rest of the year. We can consider this Lanttern's 2026 core feature.

## Current implementation

We've recently deployed an AI lesson planner agent in Lanttern.

It's a basic chat UI available in two contexts: on the strand level, and on the lesson level. The agent features can be summarized in two groups: system messages injection and tool calling.

We use **system messages injection** to add context to the conversation:

- **Strand and lesson information**
- **Custom "agents" instructions**: we have a school agents management area, where users with required permissions can manage school-level AI preferences (always applied) and custom agents settings (depends on user agent selection)
  - School settings: AI model, knowledge base, guardrails
  - Agent settings: personality, knowledge base, instructions, guardrails
- **Lesson templates**: it's the lesson expected output format. Two fields: "about" (add information about the pedagogical proposal of the template) and "template" (the template itself, the format definition)
- **User information**: name (so the AI can refer to the user using their name, feeling more personalized) and preferences (a layer of user-defined AI interaction preferences)
- **Tools args**: we add a specific system message to inform moments, subjects, and tags ids — needed on lesson creation

And we currently have **two functions** supported:

- Create lesson
- Update lesson

Summarized version:

| System messages | Functions |
|-----------------|-----------|
| School settings | Create lesson |
| Agents | Update lesson |
| Staff member info | |
| Lesson template | |
| Strand info | |
| Lesson info | |
| Tool args | |

### Oban jobs

Because LLM messages may take some time to process, I also implemented a simple Oban job to help manage those.

## Issues

This initial implementation was designed as a proof of concept (POC), and as such there are two things we need to improve:

1. **Minor adjustments before making it available to teachers**: even considering it a v0/experimental feature, there are some issues we need to address (e.g. limit tokens per user to ensure at least some level of usage control — other suggested enhancements detailed in the So What section)

2. **Better architecture**: considering agentic AI is one of the main 2026 features in Lanttern, we know in advance that this is something we'll iterate a lot. To reduce the chances of this initial POC feature snowballing into a huge mess, I think it's a good idea to use this first sprint to do some refactoring and define at least an initial (and informed) architectural direction.

---

# So What?

Considering the context and the exploratory nature of this project, we'll have one objective goal for the sprint (to avoid spending 4 weeks without a clear deliverable) but it's expected that at least part of the technical aspects will be incorporated into the deliverable.

## Deliverable: AI lesson planning v0

TBD

## Technical aspects

There are two macro definitions to focus on:

1. **Libraries for LLM interaction**
2. **System architecture**

And one subject to think about (with actual development impact starting on next sprint, probably):

3. **Agent observability, evaluation, etc.**

---

### Libraries for LLM interaction

The current implementation uses an Elixir implementation of LangChain. The initial idea was to use some library to avoid creating our own modules to handle API calling, response management/formating, and etc. (i.e. to avoid reinventing the wheel), and I choose the LangChain implementation because it's one of the established ways of interacting with LLMs in other languages.

On further research and study (and after having the opportunity to develop a feature using langchain), I think we can redefine the "tech stack" for Lanttern/LLM interaction. It's always hard to make this type of decision, especially when everything is new and there's no one default/standard implementation, but that being said, I suggest we look into the **Jido ecosystem**.

I've already reimplemented an old AI feature using req_llm (part of the Jido ecosystem) and I think it looks promising.

Considering the current implementation, my suggestion is to simply replace the langchain implementation with req_llm, while we evaluate the idea of bringing in Jido (which is more opinionated) to replace even the Oban job, serving as our core lib/tech stack to manage our agents.

---

### System architecture

Considering the future vision for agents in Lanttern, it's important to review the current system architecture (DB, processes, etc.).

The expected output is a plan: how we are thinking about the architecture taking into consideration all of the agents' requirements in terms of UX and features, at the same time we're taking care of designing a sustainable system (cost, performance).

We don't need to rush with the implementation: this should be spread across this and future sprints.

**Concepts we should take into consideration:**

- **User memory**: it's expected that each user will have lots of conversations with agents; the idea here is that on each new conversation, the agent should be aware of previous conversations with the same user, their preferences, and etc.

- **Conversation context**: instead of creating multiple conversational UIs based on the context, we want to do the opposite — a single universal conversational UI that is "context aware". In this initial iteration, we'll focus on the already existing strand and lesson context, but this scope will expand as we move forward with the development.

- **Integrated UI components**: as we're aiming to have a single conversational UI, we should spend a lot of time working on UX enhancements. One of the "features" we want to implement on the AI chat is the integration with custom UI components. For example, in the current implementation, when the AI runs the "create lesson" action, it just writes in the chat "The lesson was created" (and some other details, but still just text); it would be amazing to render a lesson card preview in the chat UI, for a better user experience.

- **Integration with files**: we should consider that part of the interactions will involve file uploads. Example: "Create a lesson plan based on the content from this PDF".

---

### Agent platform (observability, evaluation, ...)

Most of the major LLM services providers have their "AI/agent platform" offering (e.g. OpenAI, Mistral's Forge and Studio, and many others).

This is a hard decision, because there are many advantages and disadvantages for every option — including spinning our own solution.

In the same way we won't solve the full system architecture in a single sprint, it's not expected that we'll solve this platform issue soon. But it's important to keep this in our radar.

**The main aspects to take into account in this decision are:**

- **Data ownership**: the main idea here is that schools using Lanttern own their data - period. That being said, there's a lot of nuances and details in this. For example: even if we keep all of the exchanged messages between the user and the LLM, on consuming an OpenAI API for example, some of the data is also registered in the OpenAI Platform. Having this being stored in the provider is ok (as long as they don't use this for model training), the question is the next step: if we use the model evaluation and fine tuning features in the OpenAI platform, this is data that will live only in the OpenAI DB, not Lanttern's. Is this an issue, or a price to pay for not having to develop our own AI management platform?

- **Vendor lock-in**: continuing on the scenario above, another issue of using the OpenAI platform is that it will work only for GPT models. What if we decide to use Google, Anthropic, Kimi, or any other model in the future? What if our system architecture relies on mixing different models from different providers?
