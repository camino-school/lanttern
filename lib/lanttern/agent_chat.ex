defmodule Lanttern.AgentChat do
  @moduledoc """
  The AgentChat context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Lanttern.Repo

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
  alias Lanttern.LLM
  alias Lanttern.SchoolConfig
  alias Lanttern.Schools

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
    new_conversation_changeset =
      %Conversation{}
      |> Conversation.changeset(%{}, scope)
      |> Conversation.status_changeset(%{status: "processing"})

    Multi.new()
    |> Multi.insert(:conversation, new_conversation_changeset)
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
  Renames an existing conversation based on the LLM result messages.

  The AI agent will use this function to name unnamed conversations
  based on the initial user messages and model responses (first 4 messages max).

  Uses structured output (`generate_object`) to ensure consistent results.

  ## Examples

      iex> rename_conversation_from_result(scope, conversation, result, model)
      {:ok, %Conversation{}}

  """
  def rename_conversation_from_result(
        %Scope{} = scope,
        %Conversation{name: nil} = conversation,
        %LLM.Response{} = result,
        model,
        opts \\ []
      ) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    llm_module = Keyword.get(opts, :llm_module, Lanttern.LLM)

    # Extract context from result messages (user message + assistant response)
    context =
      result.messages
      |> Enum.filter(&(&1.role in [:user, :assistant]))
      |> Enum.take(4)
      |> Enum.map_join("\n", fn msg ->
        "#{msg.role}: #{msg.content}"
      end)

    naming_prompt = """
    Based on the following conversation excerpt, generate a concise title (max 50 characters) that captures the main topic or intent.

    #{context}
    """

    title_schema = [
      title: [type: :string, required: true, doc: "The conversation title (max 50 characters)"]
    ]

    case llm_module.generate_object(model, naming_prompt, title_schema) do
      {:ok, response} ->
        title =
          response.object
          |> Map.get("title", "")
          |> String.slice(0, 50)

        rename_conversation(scope, conversation, title)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Adds a user message to an existing conversation.

  ## Examples

      iex> add_user_message(scope, conversation, "Hello")
      {:ok, %Message{}}

  """
  def add_user_message(%Scope{} = scope, %Conversation{} = conversation, content) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    Multi.new()
    |> Multi.update(
      :set_processing,
      Conversation.status_changeset(conversation, %{status: "processing", last_error: nil})
    )
    |> Multi.insert(
      :message,
      Message.changeset(%Message{}, %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      })
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} -> {:ok, message}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Marks a conversation as processing, clearing any previous error.

  ## Examples

      iex> mark_conversation_processing(scope, conversation)
      {:ok, %Conversation{}}

  """
  def mark_conversation_processing(%Scope{} = scope, %Conversation{} = conversation) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    conversation
    |> Conversation.status_changeset(%{status: "processing", last_error: nil})
    |> Repo.update()
  end

  @doc """
  Marks a conversation as idle, optionally setting a last_error message.

  Called by the worker on success (no error) or failure (with error message).

  ## Examples

      iex> mark_conversation_idle(scope, conversation)
      {:ok, %Conversation{}}

      iex> mark_conversation_idle(scope, conversation, "Failed to get AI response")
      {:ok, %Conversation{}}

  """
  def mark_conversation_idle(%Scope{} = scope, %Conversation{} = conversation, error \\ nil) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    conversation
    |> Conversation.status_changeset(%{status: "idle", last_error: error})
    |> Repo.update()
  end

  @doc """
  Executes an LLM request with the given conversation messages.

  Converts a list of `Message` structs into LLM message format and runs
  them through the provided model with an automatic tool-calling loop.

  System messages are concatenated into a single message following
  a fixed order to benefit from prompt caching.

  ## Options

    * `:agent_id` - Adds agent info as system messages
    * `:lesson_template_id` - Adds template info as system messages
    * `:strand_id` - Adds strand info as system messages
    * `:lesson_id` - Adds lesson info as system messages
    * `:enabled_functions` - Add tools based on given functions
    * `:llm_module` - Module for LLM calls (default: `Lanttern.LLM`)

  ### Available functions

    * `"create_lesson"` - Requires `strand_id` in opts
    * `"update_lesson"` - Requires `lesson_id` in opts

  ## Examples

      iex> run_llm_chain(scope, messages, "gpt-4o")
      {:ok, %LLM.Response{}}
  """
  @spec run_llm_chain(Scope.t(), [Message.t()], String.t(), Keyword.t()) ::
          {:ok, LLM.Response.t()} | {:error, term()}
  def run_llm_chain(%Scope{} = scope, messages, model, opts \\ []) do
    # check if last message is a user message (prevent LLM from running improperly)
    %{role: "user"} = messages |> Enum.at(-1)

    llm_module = Keyword.get(opts, :llm_module, Lanttern.LLM)

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

    # Build system content strings in a fixed order for prompt caching.
    # School messages come first to establish baseline that agents build upon.
    system_contents =
      build_school_system_contents(scope) ++
        build_agent_system_contents(scope, Keyword.get(opts, :agent_id)) ++
        build_staff_member_system_contents(scope) ++
        build_lesson_template_system_contents(scope, Keyword.get(opts, :lesson_template_id)) ++
        build_strand_system_contents(scope, strand) ++
        build_lesson_system_contents(scope, Keyword.get(opts, :lesson_id)) ++
        build_tools_args_contents(scope, opts, strand)

    # Concatenate into a single system message
    system_message =
      case system_contents do
        [] -> []
        contents -> [LLM.system_message(Enum.join(contents, "\n\n"))]
      end

    # Convert conversation messages to LLM format
    conversation_messages =
      Enum.map(messages, fn msg ->
        case msg.role do
          "user" -> LLM.user_message(msg.content)
          "assistant" -> LLM.assistant_message(msg.content)
          "system" -> LLM.system_message(msg.content)
        end
      end)

    all_messages = system_message ++ conversation_messages
    tools = build_tools(scope, opts)

    llm_module.generate_text_with_tools(model, all_messages, tools)
  end

  defp build_school_system_contents(scope) do
    case SchoolConfig.get_ai_config(scope) do
      nil ->
        []

      school_ai_config ->
        [
          {"school_knowledge", school_ai_config.knowledge},
          {"school_guardrails", school_ai_config.guardrails}
        ]
        |> Enum.filter(fn {_, value} -> is_binary(value) and value != "" end)
        |> Enum.map(fn {tag, value} -> "<#{tag}>#{value}</#{tag}>" end)
    end
  end

  defp build_agent_system_contents(scope, agent_id)

  defp build_agent_system_contents(scope, agent_id) when is_integer(agent_id) do
    agent = Agents.get_agent!(scope, agent_id)

    [
      {"agent_personality", agent.personality},
      {"agent_instructions", agent.instructions},
      {"agent_knowledge", agent.knowledge},
      {"agent_guardrails", agent.guardrails}
    ]
    |> Enum.filter(fn {_, value} -> is_binary(value) and value != "" end)
    |> Enum.map(fn {tag, value} -> "<#{tag}>#{value}</#{tag}>" end)
  end

  defp build_agent_system_contents(_scope, _agent_id), do: []

  defp build_staff_member_system_contents(%Scope{staff_member_id: nil}),
    do: []

  defp build_staff_member_system_contents(%Scope{staff_member_id: staff_member_id}) do
    staff_member = Schools.get_staff_member!(staff_member_id)

    fields = [
      {"name", staff_member.name},
      {"role", staff_member.role},
      {"about", staff_member.about},
      {"preferences", staff_member.agent_conversation_preferences}
    ]

    inner =
      fields
      |> Enum.filter(fn {_, v} -> is_binary(v) and v != "" end)
      |> Enum.map_join("\n", fn {tag, value} -> "<#{tag}>#{value}</#{tag}>" end)

    ["<staff_member_context>\n#{inner}\n</staff_member_context>"]
  end

  defp build_lesson_template_system_contents(scope, lesson_template_id)
       when is_integer(lesson_template_id) do
    template = LessonTemplates.get_lesson_template!(scope, lesson_template_id)

    [
      "<lesson_template_info>#{template.about}</lesson_template_info>",
      "<lesson_template>#{template.template}</lesson_template>"
    ]
  end

  defp build_lesson_template_system_contents(_scope, _lesson_template_id),
    do: []

  # strand functions doesn't support scope yet, but keep it around
  # as it should be implemented in the near future
  defp build_strand_system_contents(_scope, %Strand{} = strand) do
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

    [
      """
      <strand_context>
      <strand_name>#{strand.name}</strand_name>
      <subjects>#{subjects}</subjects>
      <years>#{years}</years>
      <curriculum>#{curriculum_items}</curriculum>
      <overview>#{strand.description}</overview>
      <teacher_instructions>#{strand.teacher_instructions || "No teacher instructions"}</teacher_instructions>
      <moments>#{moments}</moments>
      </strand_context>
      """
    ]
  end

  defp build_strand_system_contents(_scope, _strand),
    do: []

  # lessons functions doesn't support scope yet, but keep it around
  # as it should be implemented in the near future
  defp build_lesson_system_contents(_scope, lesson_id)
       when is_integer(lesson_id) do
    lesson = Lessons.get_lesson!(lesson_id, preloads: [:subjects, :tags, :moment])
    subjects = Enum.map_join(lesson.subjects, &"<subject>#{&1.name}</subject>")
    tags = Enum.map_join(lesson.tags, &"<tag>#{&1.name}</tag>")

    [
      """
      <lesson_context>
      <lesson_name>#{lesson.name}</lesson_name>
      <moment>#{lesson.moment.name}</moment>
      <subjects>#{subjects}</subjects>
      <tags>#{tags}</tags>
      <overview>#{lesson.description}</overview>
      <teacher_notes>#{lesson.teacher_notes || "No teacher notes"}</teacher_notes>
      <differentiation_notes>#{lesson.differentiation_notes || "No differentiation notes"}</differentiation_notes>
      </lesson_context>
      """
    ]
  end

  defp build_lesson_system_contents(_scope, _lesson_id),
    do: []

  defp build_tools_args_contents(scope, opts, %Strand{} = strand) do
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

      [
        """
        <tools_args>
        Internal use for tool calling only. Not sensitive, but not relevant for users.
        <moments>#{moments}</moments>
        <subjects>#{subjects}</subjects>
        <tags>#{tags}</tags>
        </tools_args>
        """
      ]
    else
      []
    end
  end

  defp build_tools_args_contents(_scope, _opts, _strand),
    do: []

  defp build_tools(scope, opts) do
    enabled_functions = Keyword.get(opts, :enabled_functions, [])

    []
    |> maybe_add_create_lesson_tool(
      "create_lesson" in enabled_functions,
      scope,
      Keyword.get(opts, :strand_id)
    )
    |> maybe_add_update_lesson_tool(
      "update_lesson" in enabled_functions,
      scope,
      Keyword.get(opts, :lesson_id)
    )
  end

  defp maybe_add_create_lesson_tool(tools, true, scope, strand_id)
       when is_integer(strand_id) do
    tool =
      LLM.tool(
        "create_lesson",
        "Create a lesson in the current strand",
        create_lesson_tool_params(),
        fn args ->
          args = Map.put(args, :strand_id, strand_id)

          case Lessons.create_lesson(scope, args, is_ai_agent: true) do
            {:ok, _created_lesson} ->
              {:ok, "SUCCESS: lesson was created successfully"}

            {:error, changeset} ->
              {:error, "ERROR: #{changeset_error_to_string(changeset)}"}
          end
        end
      )

    [tool | tools]
  end

  defp maybe_add_create_lesson_tool(tools, _, _, _), do: tools

  defp maybe_add_update_lesson_tool(tools, true, scope, lesson_id)
       when is_integer(lesson_id) do
    tool =
      LLM.tool(
        "update_lesson",
        "Update the current lesson description and/or teacher notes and/or diff notes",
        update_lesson_tool_params(),
        fn args ->
          lesson = Lessons.get_lesson!(lesson_id)

          case Lessons.update_lesson(scope, lesson, args, is_ai_agent: true) do
            {:ok, _updated_lesson} ->
              {:ok, "SUCCESS: lesson was updated successfully"}

            {:error, changeset} ->
              {:error, "ERROR: #{changeset_error_to_string(changeset)}"}
          end
        end
      )

    [tool | tools]
  end

  defp maybe_add_update_lesson_tool(tools, _, _, _), do: tools

  # `name` is required on create because the `Lesson` changeset validates it.
  # Keeping it optional here would let the LLM skip it and trigger avoidable
  # "name: can't be blank" failures that cost a retry round.
  defp create_lesson_tool_params do
    [name: [type: :string, required: true, doc: "The lesson name/title"]] ++
      shared_lesson_tool_params()
  end

  # On update the existing `Lesson` already has a name, so omitting it is
  # intentional — the LLM can tweak just description/notes without rewriting
  # the title.
  defp update_lesson_tool_params do
    [name: [type: :string, doc: "The lesson name/title"]] ++ shared_lesson_tool_params()
  end

  defp shared_lesson_tool_params do
    [
      moment_id: [type: :integer, doc: "The moment in which the lesson will be attached to"],
      subjects_ids: [
        type: {:list, :integer},
        doc: "The subjects linked to the lesson"
      ],
      tags_ids: [type: {:list, :integer}, doc: "Tags linked to the lesson"],
      description: [
        type: :string,
        doc: "The main lesson content, shared with students when lesson is published"
      ],
      teacher_notes: [
        type: :string,
        doc: "Instructions and notes for teachers, never shared with students"
      ],
      differentiation_notes: [
        type: :string,
        doc: "Instructions for lesson differentiation, never shared with students"
      ]
    ]
  end

  defp changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(safe_to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
  end

  # `String.to_existing_atom/1` raises when the key has never been loaded into
  # the atom table. That can happen for placeholders coming from gettext
  # translations or from libraries that are lazily loaded. In that case we
  # return a value guaranteed not to match any key in `opts` so the lookup
  # falls back to the raw placeholder string.
  defp safe_to_existing_atom(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> :__unknown_changeset_placeholder__
  end

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
