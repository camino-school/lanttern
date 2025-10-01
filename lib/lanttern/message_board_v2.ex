defmodule Lanttern.MessageBoardV2 do
  @moduledoc """
  The MessageBoardV2 context - Version 2
  """
  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers
  alias Lanttern.MessageBoard.MessageV2, as: Message
  alias Lanttern.MessageBoard.Section

  @doc """
  Returns the list of messages.
  """
  def list_messages(opts \\ []) do
    from(m in Message,
      group_by: m.id,
      order_by: [asc: m.updated_at, asc: m.position]
    )
    |> apply_list_messages_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_messages_opts(queryable, []), do: queryable

  defp apply_list_messages_opts(queryable, [{:school_id, school_id} | opts]) do
    case Keyword.get(opts, :classes_ids) do
      classes_ids when is_list(classes_ids) and classes_ids != [] ->
        from(m in queryable,
          left_join: mc in assoc(m, :message_classes),
          where:
            (m.send_to == :school and m.school_id == ^school_id) or mc.class_id in ^classes_ids
        )

      _ ->
        from(m in queryable, where: m.school_id == ^school_id)
    end
    |> apply_list_messages_opts(opts)
  end

  defp apply_list_messages_opts(queryable, [_ | opts]),
    do: apply_list_messages_opts(queryable, opts)

  @doc """
  Gets a single message.
  """
  def get_message(id, opts \\ []) do
    Repo.get(Message, id) |> maybe_preload(opts)
  end

  @doc """
  Gets a single message or raises.
  """
  def get_message!(id, opts \\ []) do
    Repo.get!(Message, id) |> maybe_preload(opts)
  end

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{} |> Message.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a message.
  """
  def update_message(%Message{} = message, attrs) do
    message |> Message.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%Message{} = message), do: Repo.delete(message)

  @doc """
  Returns a changeset for tracking message changes.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def get_message_per_school(id, school_id) do
    from(m in Message, where: m.id == ^id and m.school_id == ^school_id)
    |> preload([:classes])
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end

  @doc """
  Returns sections ordered by position for a school.
  """
  def list_sections(opts \\ []) do
    from(s in Section, order_by: s.position)
    |> apply_list_sections_opts(opts)
    |> Repo.all()
  end

  defp apply_list_sections_opts(queryable, []), do: queryable

  defp apply_list_sections_opts(queryable, [{:school_id, school_id} | opts]) do
    case Keyword.get(opts, :classes_ids) do
      classes_ids when is_list(classes_ids) and classes_ids != [] ->
        messages_query =
          from(m in Message, where: is_nil(m.archived_at), order_by: m.position)
          |> apply_sections_filter_opts(classes_ids: classes_ids, school_id: school_id)
          |> preload([:classes])

        from(s in queryable, where: s.school_id == ^school_id)
        |> preload(messages: ^messages_query)

      _ ->
        from(s in queryable, where: s.school_id == ^school_id)
    end
    |> apply_list_sections_opts(opts)
  end

  defp apply_list_sections_opts(queryable, [_ | opts]),
    do: apply_list_sections_opts(queryable, opts)

  defp apply_sections_filter_opts(queryable, opts) do
    case Keyword.get(opts, :school_id) do
      nil ->
        queryable

      school_id ->
        case Keyword.get(opts, :classes_ids) do
          classes_ids when is_list(classes_ids) and classes_ids != [] ->
            from(m in queryable,
              left_join: mc in assoc(m, :message_classes),
              where:
                (m.send_to == :school and m.school_id == ^school_id) or
                  mc.class_id in ^classes_ids
            )

          _ ->
            from(m in queryable, where: m.school_id == ^school_id)
        end
    end
  end

  @doc """
  Gets a section or raises.
  """
  def get_section!(id), do: Repo.get!(Section, id)

  @doc """
  Gets a section with ordered messages.
  """
  def get_section_with_ordered_messages!(id) do
    messages_query =
      from(
        m in Message,
        order_by: [
          asc: m.position,
          desc: m.updated_at,
          asc: m.archived_at
        ]
      )

    Section
    |> Repo.get!(id)
    |> Repo.preload(messages: messages_query)
  end

  @doc """
  Creates a section.
  """
  def create_section(attrs) do
    %Section{} |> Section.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a section.
  """
  def update_section(%Section{} = section, attrs) do
    section |> Section.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a section.
  """
  def delete_section(%Section{} = section), do: Repo.delete(section)

  @doc """
  Returns a changeset for tracking section changes.
  """
  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.changeset(section, attrs)
  end

  def update_messages_position(messages) do
    messages_ids =
      messages
      |> Enum.filter(fn m -> is_nil(m.archived_at) end)
      |> Enum.map(& &1.id)

    update_positions(Message, messages_ids)
  end

  def update_section_position(sections) when is_list(sections) do
    sections_ids = Enum.map(sections, & &1.id)
    update_positions(Section, sections_ids)
  end

  def update_sections_positions(sections_ids) when is_list(sections_ids),
    do: update_positions(Section, sections_ids)
end
