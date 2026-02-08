defmodule Lanttern.AgentChat do
  @moduledoc """
  The AgentChat context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Lanttern.Repo

  alias LangChain.Chains.LLMChain
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias LangChain.Message.ContentPart

  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.AgentChat.StrandConversation
  alias Lanttern.Agents
  alias Lanttern.Curricula
  alias Lanttern.Identity.Scope
  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Lessons
  alias Lanttern.LessonTemplates
  alias Lanttern.SchoolConfig

  @doc """
  Subscribes to scoped notifications about chain responses in conversations.

  The broadcasted messages match the pattern:

    * {:conversation, {:failed, error}}
    * {:conversation, {:message_added, %Message{}}}
    * {:conversation, {:conversation_renamed, %Conversation{}}}

  """
  def subscribe_conversation(conversation_id) do
    Phoenix.PubSub.subscribe(Lanttern.PubSub, "conversation:#{conversation_id}")
  end

  def broadcast_conversation(conversation_id, message) do
    Phoenix.PubSub.broadcast(
      Lanttern.PubSub,
      "conversation:#{conversation_id}",
      {:conversation, message}
    )
  end

  @doc """
  Returns the list of conversations for the given scope profile.

  ## Options

    * `:strand_id` - Filters conversations linked to the given strand
    * `:lesson_id` - Filters conversations linked to the given lesson (requires a strand link). Supports `nil` (useful for listing strand conversations only)

  ## Examples

      iex> list_conversations(scope)
      [%Conversation{}, ...]

      iex> list_conversations(scope, strand_id: 1)
      [%Conversation{}, ...]

      iex> list_conversations(scope, strand_id: 1, lesson_id: 2)
      [%Conversation{}, ...]

  """
  def list_conversations(%Scope{} = scope, opts \\ []) do
    from(
      c in Conversation,
      where: c.profile_id == ^scope.profile_id,
      order_by: [desc: :updated_at]
    )
    |> apply_list_conversations_opts(opts)
    |> Repo.all()
  end

  defp apply_list_conversations_opts(queryable, []),
    do: queryable

  defp apply_list_conversations_opts(queryable, [{:strand_id, strand_id} | opts]) do
    queryable
    |> maybe_join_strand_conversation()
    |> where([_c, strand_conversation: sc], sc.strand_id == ^strand_id)
    |> apply_list_conversations_opts(opts)
  end

  defp apply_list_conversations_opts(queryable, [{:lesson_id, lesson_id} | opts]) do
    conditions =
      if is_nil(lesson_id) do
        dynamic([_c, strand_conversation: sc], is_nil(sc.lesson_id))
      else
        dynamic([_c, strand_conversation: sc], sc.lesson_id == ^lesson_id)
      end

    queryable
    |> maybe_join_strand_conversation()
    |> where(^conditions)
    |> apply_list_conversations_opts(opts)
  end

  defp apply_list_conversations_opts(queryable, [_ | opts]),
    do: apply_list_conversations_opts(queryable, opts)

  defp maybe_join_strand_conversation(queryable) do
    if has_named_binding?(queryable, :strand_conversation) do
      queryable
    else
      join(
        queryable,
        :inner,
        [c],
        sc in assoc(c, :strand_conversation),
        as: :strand_conversation
      )
    end
  end

  @doc """
  Gets a single conversation.

  Returns `nil` if the Conversation does not exist.

  ## Examples

      iex> get_conversation(scope, 123)
      %Conversation{}

  """
  def get_conversation(%Scope{} = scope, id) do
    from(
      c in Conversation,
      where: c.id == ^id,
      where: c.profile_id == ^scope.profile_id
    )
    |> Repo.one()
  end

  @doc """
  Lists conversation messages.

  ## Examples

      iex> list_conversation_messages(scope, conversation)
      [%Message{}, ...]

  """
  def list_conversation_messages(%Scope{} = scope, %Conversation{} = conversation) do
    true = scope.profile_id == conversation.profile_id

    from(
      m in Message,
      where: m.conversation_id == ^conversation.id,
      order_by: m.inserted_at
    )
    |> Repo.all()
  end

  @doc """
  Creates a model call record for tracking token usage.

  ## Examples

      iex> create_model_call(%{prompt_tokens: 10, completion_tokens: 20}, message_id)
      {:ok, %ModelCall{}}

  """
  def create_model_call(attrs, message_id) do
    attrs = Map.put(attrs, :message_id, message_id)

    %ModelCall{}
    |> ModelCall.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a new conversation with an initial user message.

  Returns the conversation and message in a multi result.

  ## Options

    * `:strand_id` - Links the conversation to a strand
    * `:lesson_id` - Links the conversation to a specific lesson (requires `:strand_id`)

  ## Examples

      iex> create_conversation_with_message(scope, "Hello")
      {:ok, %{conversation: %Conversation{}, user_message: %Message{}}}

      iex> create_conversation_with_message(scope, "Hello", strand_id: 1, lesson_id: 2)
      {:ok, %{conversation: %Conversation{}, user_message: %Message{}, strand_conversation: %StrandConversation{}}}

  """
  def create_conversation_with_message(%Scope{} = scope, content, opts \\ []) do
    Multi.new()
    |> Multi.insert(:conversation, Conversation.changeset(%Conversation{}, %{}, scope))
    |> Multi.insert(:user_message, fn %{conversation: conversation} ->
      Message.changeset(%Message{}, %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      })
    end)
    |> maybe_insert_strand_conversation(opts)
    |> Repo.transaction()
  end

  defp maybe_insert_strand_conversation(multi, opts) do
    case Keyword.get(opts, :strand_id) do
      nil ->
        multi

      strand_id ->
        Multi.insert(multi, :strand_conversation, fn %{conversation: conversation} ->
          StrandConversation.changeset(%StrandConversation{}, %{
            conversation_id: conversation.id,
            strand_id: strand_id,
            lesson_id: Keyword.get(opts, :lesson_id)
          })
        end)
    end
  end

  @doc """
  Renames a conversation.

  ## Examples

      iex> rename_conversation(scope, conversation, "New name")
      {:ok, %Conversation{}}

  """
  def rename_conversation(%Scope{} = scope, %Conversation{} = conversation, name)
      when is_binary(name) and name != "" do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    conversation
    |> Conversation.rename_changeset(%{name: name})
    |> Repo.update()
  end

  @doc """
  Renames an existing conversation based on chain messages.

  The AI agent will use this function to name unnamed conversations
  based on the initial user messages and model responses (first 4 messages max).

  Uses LLM function calling to ensure consistent, structured output.

  ## Examples

      iex> rename_conversation_based_on_chain(scope, conversation, chain)
      {:ok, %Conversation{}}

  """
  def rename_conversation_based_on_chain(
        %Scope{} = scope,
        %Conversation{name: nil} = conversation,
        chain
      ) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    # Extract context from chain messages (user message + assistant response)
    context =
      chain.messages
      |> Enum.filter(&(&1.role in [:user, :assistant]))
      |> Enum.take(4)
      |> Enum.map_join("\n", fn msg ->
        "#{msg.role}: #{ContentPart.content_to_string(msg.content)}"
      end)

    rename_function = build_rename_function(scope, conversation)

    naming_prompt = """
    Based on the following conversation excerpt, generate a concise title (max 50 characters) that captures the main topic or intent. Use the set_conversation_title function to set the title.

    #{context}
    """

    naming_chain =
      LLMChain.new!(%{llm: chain.llm})
      |> LLMChain.add_tools([rename_function])
      |> LLMChain.add_message(LangChain.Message.new_user!(naming_prompt))

    case LLMChain.run(naming_chain, mode: :while_needs_response) do
      {:ok, updated_chain} ->
        # The function was executed - find the tool result to get the conversation
        tool_result =
          updated_chain.messages
          |> Enum.find(&(&1.role == :tool))

        case tool_result do
          %{tool_results: [%{processed_content: %Conversation{} = updated_conversation}]} ->
            {:ok, updated_conversation}

          _ ->
            # Fallback: reload conversation from DB
            {:ok, Repo.get!(Conversation, conversation.id)}
        end

      {:error, _chain, error} ->
        {:error, error}
    end
  end

  defp build_rename_function(scope, conversation) do
    LangChain.Function.new!(%{
      name: "set_conversation_title",
      description:
        "Sets the title for this conversation. The title should be concise (max 50 characters) and capture the main topic.",
      parameters: [
        LangChain.FunctionParam.new!(%{
          name: "title",
          type: :string,
          description: "The conversation title (max 50 characters)",
          required: true
        })
      ],
      function: fn %{"title" => title}, _context ->
        title = String.slice(title, 0, 50)

        case rename_conversation(scope, conversation, title) do
          {:ok, updated_conversation} ->
            {:ok, "Title set to: #{title}", updated_conversation}

          {:error, changeset} ->
            {:error, "Failed to set title: #{inspect(changeset.errors)}"}
        end
      end
    })
  end

  @doc """
  Adds a user message to an existing conversation.

  ## Examples

      iex> add_user_message(scope, conversation, "Hello")
      {:ok, %Message{}}

  """
  def add_user_message(%Scope{} = scope, %Conversation{} = conversation, content) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    attrs =
      %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      }

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Executes an LLM chain with the given conversation messages.

  Converts a list of `Message` structs into LangChain message format and runs
  them through the provided LLM model.

  When adding system messages, this function prepends them to the chain
  following always the same order to benefit from prompt caching.

  ## Options

    * `:agent_id` - Adds agent info as system messages
    * `:lesson_template_id` - Adds template info as system messages
    * `:strand_id` - Adds strand info as system messages
    * `:lesson_id` - Adds lesson info as system messages
    * `:enabled_functions` - Add tools to the chain based on given functions

  ### Available functions

    * `"create_lesson"` - Requires `strand_id` in opts
    * `"update_lesson"` - Requires `lesson_id` in opts

  ## Examples

      iex> run_llm_chain(scope, messages, llm)
      {:ok, %LLMChain{}}
  """
  @spec run_llm_chain(Scope.t(), [Message.t()], any(), Keyword.t()) ::
          {:ok, LLMChain.t()} | {:error, LLMChain.t(), LangChain.LangChainError.t()}
  def run_llm_chain(%Scope{} = scope, messages, llm, opts \\ []) do
    # check if last message is a user message (prevent LLM from running improperly)
    %{role: "user"} = messages |> Enum.at(-1)

    # as strand is used in different helper functions,
    # request it once if needed and reuse it in all functions
    strand =
      case Keyword.get(opts, :strand_id) do
        id when is_integer(id) ->
          LearningContext.get_strand!(id,
            preloads: [:subjects, :years, :moments]
          )

        _ ->
          nil
      end

    # we're not using the recursive pattern for opts here
    # because in this use we want to control messages ordering (prompt caching)
    # School messages come first to establish baseline that agents build upon
    system_messages =
      add_school_system_messages(scope)
      |> add_agent_system_messages(
        scope,
        Keyword.get(opts, :agent_id)
      )
      |> add_lesson_template_system_messages(
        scope,
        Keyword.get(opts, :lesson_template_id)
      )
      |> add_strand_system_messages(scope, strand)
      |> add_lesson_system_messages(
        scope,
        Keyword.get(opts, :lesson_id)
      )
      |> add_tools_args_messages(scope, opts, strand)

    tools = setup_llm_chain_tools(scope, opts)

    context = setup_llm_chain_context(opts)

    # Build LangChain messages from conversation messages
    langchain_messages =
      Enum.map(messages, fn msg ->
        case msg.role do
          "user" -> LangChain.Message.new_user!(msg.content)
          "assistant" -> LangChain.Message.new_assistant!(msg.content)
          "system" -> LangChain.Message.new_system!(msg.content)
        end
      end)

    %{
      llm: llm,
      custom_context: context,
      # 5 minutes in milliseconds
      async_tool_timeout: 5 * 60 * 1000
    }
    |> LLMChain.new!()
    |> LLMChain.add_messages(system_messages)
    |> LLMChain.add_messages(langchain_messages)
    |> LLMChain.add_tools(tools)
    |> LLMChain.run(mode: :while_needs_response)
  end

  defp add_school_system_messages(scope) do
    case SchoolConfig.get_ai_config(scope) do
      nil ->
        []

      school_ai_config ->
        [
          {"school_knowledge", school_ai_config.knowledge},
          {"school_guardrails", school_ai_config.guardrails}
        ]
        |> Enum.filter(fn {_, value} -> is_binary(value) and value != "" end)
        |> Enum.map(fn {tag, value} ->
          LangChain.Message.new_system!("<#{tag}>#{value}</#{tag}>")
        end)
    end
  end

  defp add_agent_system_messages(system_messages, scope, agent_id)

  defp add_agent_system_messages(system_messages, scope, agent_id) when is_integer(agent_id) do
    agent = Agents.get_agent!(scope, agent_id)

    agent_messages =
      [
        {"agent_personality", agent.personality},
        {"agent_instructions", agent.instructions},
        {"agent_knowledge", agent.knowledge},
        {"agent_guardrails", agent.guardrails}
      ]
      |> Enum.filter(fn {_, value} -> is_binary(value) and value != "" end)
      |> Enum.map(fn {tag, value} ->
        LangChain.Message.new_system!("<#{tag}>#{value}</#{tag}>")
      end)

    system_messages ++ agent_messages
  end

  defp add_agent_system_messages(system_messages, _scope, _agent_id), do: system_messages

  defp add_lesson_template_system_messages(system_messages, scope, lesson_template_id)
       when is_integer(lesson_template_id) do
    template = LessonTemplates.get_lesson_template!(scope, lesson_template_id)

    system_messages ++
      [
        LangChain.Message.new_system!(
          "<lesson_template_info>#{template.about}</lesson_template_info>"
        ),
        LangChain.Message.new_system!("<lesson_template>#{template.template}</lesson_template>")
      ]
  end

  defp add_lesson_template_system_messages(system_messages, _scope, _lesson_template_id),
    do: system_messages

  # strand functions doesn't support scope yet, but keep it around
  # as it should be implemented in the near future
  defp add_strand_system_messages(system_messages, _scope, %Strand{} = strand) do
    subjects = Enum.map_join(strand.subjects, "\n", &"<subject>#{&1.name}</subject>")
    years = Enum.map_join(strand.years, "\n", &"<year>#{&1.name}</year>")

    moments =
      strand.moments
      |> Enum.sort_by(& &1.position)
      |> Enum.map_join(fn moment ->
        """
        <moment>
        <name>#{moment.name}</name>
        <description>#{moment.description}</description>
        </moment>
        """
      end)

    curriculum_items =
      Curricula.list_strand_curriculum_items(
        strand.id,
        preloads: :curriculum_component
      )
      |> Enum.map_join(&"<item>#{&1.name} (#{&1.curriculum_component.name})</item>")

    system_messages ++
      [
        LangChain.Message.new_system!("""
        <strand_context>
        <strand_name>#{strand.name}</strand_name>
        <subjects>#{subjects}</subjects>
        <years>#{years}</years>
        <curriculum>#{curriculum_items}</curriculum>
        <overview>#{strand.description}</overview>
        <teacher_instructions>#{strand.teacher_instructions || "No teacher instructions"}</teacher_instructions>
        <moments>#{moments}</moments>
        </strand_context>
        """)
      ]
  end

  defp add_strand_system_messages(system_messages, _scope, _strand),
    do: system_messages

  # lessons functions doesn't support scope yet, but keep it around
  # as it should be implemented in the near future
  defp add_lesson_system_messages(system_messages, _scope, lesson_id)
       when is_integer(lesson_id) do
    lesson = Lessons.get_lesson!(lesson_id, preloads: [:subjects, :tags, :moment])
    subjects = Enum.map_join(lesson.subjects, &"<subject>#{&1.name}</subject>")
    tags = Enum.map_join(lesson.tags, &"<tag>#{&1.name}</tag>")

    system_messages ++
      [
        LangChain.Message.new_system!("""
        <lesson_context>
        <lesson_name>#{lesson.name}</lesson_name>
        <moment>#{lesson.moment.name}</moment>
        <subjects>#{subjects}</subjects>
        <tags>#{tags}</tags>
        <overview>#{lesson.description}</overview>
        <teacher_notes>#{lesson.teacher_notes || "No teacher notes"}</teacher_notes>
        <differentiation_notes>#{lesson.differentiation_notes || "No differentiation notes"}</differentiation_notes>
        </lesson_context>
        """)
      ]
  end

  defp add_lesson_system_messages(system_messages, _scope, _lesson_id),
    do: system_messages

  defp add_tools_args_messages(system_messages, scope, opts, %Strand{} = strand) do
    # it's very specific to create/update lessons right now,
    # but in the future we may extend the same structure to different tools
    lesson_functions_enabled =
      Keyword.get(opts, :enabled_functions, [])
      |> Enum.any?(&(&1 in ["create_lesson", "update_lesson"]))

    if lesson_functions_enabled do
      moments = Enum.map(strand.moments, &"<moment>name: #{&1.name}, id: #{&1.id}</moment>")
      subjects = Enum.map(strand.subjects, &"<subject>name: #{&1.name}, id: #{&1.id}</subject>")

      tags =
        Lessons.list_lesson_tags(scope)
        |> Enum.map(
          &"""
          <tag>
          name: #{&1.name}, id: #{&1.id}

          <usage>
          #{&1.agent_description}
          </usage>
          </tag>
          """
        )

      system_messages ++
        [
          LangChain.Message.new_system!("""
          <tools_args>
          Internal use for tool calling only. Not sensitive, but not relevant for users.
          <moments>#{moments}</moments>
          <subjects>#{subjects}</subjects>
          <tags>#{tags}</tags>
          </tools_args>
          """)
        ]
    else
      system_messages
    end
  end

  defp add_tools_args_messages(system_messages, _scope, _opts, _strand),
    do: system_messages

  defp setup_llm_chain_tools(scope, opts) do
    enabled_functions = Keyword.get(opts, :enabled_functions, [])

    []
    |> setup_create_lesson_function(
      "create_lesson" in enabled_functions,
      scope,
      Keyword.get(opts, :strand_id)
    )
    |> setup_update_lesson_function(
      "update_lesson" in enabled_functions,
      scope,
      Keyword.get(opts, :lesson_id)
    )
  end

  defp setup_create_lesson_function(tools, true, scope, strand_id) when is_integer(strand_id) do
    function =
      Function.new!(%{
        name: "create_lesson",
        description: "Create a lesson in the current strand",
        parameters: lesson_function_params(),
        function: fn args, %{strand_id: strand_id} = _context ->
          args = Map.put(args, "strand_id", strand_id)

          case Lessons.create_lesson(scope, args, is_ai_agent: true) do
            {:ok, created_lesson} ->
              {:ok, "SUCCESS: lesson was created successfully", created_lesson}

            {:error, changeset} ->
              {:error, "ERROR: #{LangChain.Utils.changeset_error_to_string(changeset)}"}
          end
        end
      })

    [function | tools]
  end

  defp setup_create_lesson_function(tools, _, _, _), do: tools

  defp setup_update_lesson_function(tools, true, scope, lesson_id) when is_integer(lesson_id) do
    function =
      Function.new!(%{
        name: "update_lesson",
        description:
          "Update the current lesson description and/or teacher notes and/or diff notes",
        parameters: lesson_function_params(),
        function: fn args, %{lesson_id: lesson_id} = _context ->
          lesson = Lessons.get_lesson!(lesson_id)

          case Lessons.update_lesson(scope, lesson, args, is_ai_agent: true) do
            {:ok, updated_lesson} ->
              {:ok, "SUCCESS: lesson was updated successfully", updated_lesson}

            {:error, changeset} ->
              {:error, "ERROR: #{LangChain.Utils.changeset_error_to_string(changeset)}"}
          end
        end
      })

    [function | tools]
  end

  defp setup_update_lesson_function(tools, _, _, _), do: tools

  defp lesson_function_params do
    [
      FunctionParam.new!(%{
        name: "moment_id",
        type: "integer",
        description: "The moment in which the lesson will be attached to"
      }),
      FunctionParam.new!(%{
        name: "subjects_ids",
        type: "array",
        item_type: "integer",
        description: "The subjects linked to the lesson"
      }),
      FunctionParam.new!(%{
        name: "tags_ids",
        type: "array",
        item_type: "integer",
        description: "Tags linked to the lesson"
      }),
      FunctionParam.new!(%{
        name: "description",
        type: "string",
        description: "The main lesson content, shared with students when lesson is published"
      }),
      FunctionParam.new!(%{
        name: "teacher_notes",
        type: "string",
        description: "Instructions and notes for teachers, never shared with students"
      }),
      FunctionParam.new!(%{
        name: "differentiation_notes",
        type: "string",
        description: "Instructions for lesson differentiation, never shared with students"
      })
    ]
  end

  defp setup_llm_chain_context(context \\ %{}, opts)

  defp setup_llm_chain_context(context, []), do: context

  defp setup_llm_chain_context(context, [{:strand_id, strand_id} | opts])
       when is_integer(strand_id) do
    Map.put(context, :strand_id, strand_id)
    |> setup_llm_chain_context(opts)
  end

  defp setup_llm_chain_context(context, [{:lesson_id, lesson_id} | opts])
       when is_integer(lesson_id) do
    Map.put(context, :lesson_id, lesson_id)
    |> setup_llm_chain_context(opts)
  end

  defp setup_llm_chain_context(context, [_ | opts]),
    do: setup_llm_chain_context(context, opts)

  @doc """
  Adds an assistant message to a conversation with model call tracking.

  ## Examples

      iex> add_assistant_message(conversation_id, "Hello!", %{prompt_tokens: 10, completion_tokens: 20, model: "gpt-5-nano"})
      {:ok, %{message: %Message{}, model_call: %ModelCall{}}}

  """
  def add_assistant_message(conversation_id, content, usage_attrs) do
    Multi.new()
    |> Multi.insert(
      :message,
      Message.changeset(%Message{}, %{
        role: "assistant",
        content: content,
        conversation_id: conversation_id
      })
    )
    |> Multi.insert(:model_call, fn %{message: message} ->
      ModelCall.changeset(%ModelCall{}, Map.put(usage_attrs, :message_id, message.id))
    end)
    |> Multi.update(
      :touch_conversation,
      fn %{message: message} ->
        conversation = Repo.get!(Conversation, message.conversation_id)
        Ecto.Changeset.change(conversation, %{})
      end,
      # force true to update updated_at timestamp
      force: true
    )
    |> Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation rename changes.

  ## Examples

      iex> change_conversation_name(scope, conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation_name(%Scope{} = scope, %Conversation{} = conversation, attrs \\ %{}) do
    true = Scope.matches_profile?(scope, conversation.profile_id)
    Conversation.rename_changeset(conversation, attrs)
  end
end
