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
    attrs_with_position = set_position(attrs)
    %Message{} |> Message.changeset(attrs_with_position) |> Repo.insert()
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
  Returns sections ordered by position.

  ## Options

    * `:school_id` - filters sections by school
    * `:archived` - includes archived sections if true

  ## Examples

      # Get all sections for a school
      list_sections(school_id: 1)

      # Get sections including archived ones
      list_sections(school_id: 1, archived: true)

  """
  def list_sections(opts \\ []) do
    from(s in Section, order_by: s.position)
    |> apply_list_sections_opts(opts)
    |> Repo.all()
  end

  defp apply_list_sections_opts(queryable, []), do: queryable

  defp apply_list_sections_opts(queryable, [{:school_id, school_id} | opts]) do
    from(s in queryable, where: s.school_id == ^school_id)
    |> apply_list_sections_opts(opts)
  end

  defp apply_list_sections_opts(queryable, [{:archived, include_archived?} | opts]) do
    case include_archived? do
      true -> queryable
      _ -> from(s in queryable, where: is_nil(s.archived_at))
    end
    |> apply_list_sections_opts(opts)
  end

  defp apply_list_sections_opts(queryable, [_ | opts]),
    do: apply_list_sections_opts(queryable, opts)

  @doc """
  Returns sections with their filtered messages for a school.

  This function preloads messages filtered by classes and excludes archived messages.
  Use this when you need sections with their related messages for display purposes.

  ## Examples

      # Get sections with messages filtered by specific classes
      list_sections_with_filtered_messages(1, [2, 3])

  """
  def list_sections_with_filtered_messages(school_id, classes_ids) when is_list(classes_ids) do
    messages_query =
      from(m in Message,
        where: is_nil(m.archived_at),
        order_by: [
          asc: m.position,
          desc: m.updated_at,
          asc: m.archived_at
        ]
      )
      |> apply_message_filter_by_classes(school_id, classes_ids)
      |> preload([:classes])

    from(s in Section, where: s.school_id == ^school_id, order_by: s.position)
    |> preload(messages: ^messages_query)
    |> Repo.all()
  end

  defp apply_message_filter_by_classes(queryable, school_id, classes_ids) do
    case classes_ids do
      [] ->
        from(m in queryable, where: m.school_id == ^school_id)

      classes_ids when is_list(classes_ids) ->
        from(m in queryable,
          left_join: mc in assoc(m, :message_classes),
          where:
            (m.send_to == :school and m.school_id == ^school_id) or
              mc.class_id in ^classes_ids
        )
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

  defp set_position(attrs) do
    position_key = if is_map_key(attrs, "position") or is_map_key(attrs, :position), do: get_position_key(attrs), else: nil

    case position_key && Map.get(attrs, position_key) do
      nil ->
        section_id = Map.get(attrs, "section_id") || Map.get(attrs, :section_id)
        next_position = get_next_position_for_section(section_id)
        key = get_consistent_key(attrs)
        Map.put(attrs, key, next_position)

      _position ->
        attrs
    end
  end

  defp get_position_key(attrs) do
    cond do
      Map.has_key?(attrs, "position") -> "position"
      Map.has_key?(attrs, :position) -> :position
      true -> nil
    end
  end

  defp get_consistent_key(attrs) do
    if Enum.any?(Map.keys(attrs), &is_binary/1), do: "position", else: :position
  end

  defp get_next_position_for_section(section_id) when is_nil(section_id), do: 0

  defp get_next_position_for_section(section_id) do
    from(m in Message,
      where: m.section_id == ^section_id and is_nil(m.archived_at),
      select: count()
    )
    |> Repo.one()
  end
end
