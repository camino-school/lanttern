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
  Returns the list of messages ordered by updated_at and position.

  ## Options

    * `:school_id` - filters messages by school
    * `:classes_ids` - when combined with school_id, filters messages by classes

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

      iex> list_messages(school_id: 1)
      [%Message{}, ...]

      iex> list_messages(school_id: 1, classes_ids: [1, 2])
      [%Message{}, ...]

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
  Gets a single message by ID.

  Returns the message or `nil` if not found.

  ## Options

    * `:preload` - list of associations to preload

  ## Examples

      iex> get_message(1)
      %Message{}

      iex> get_message(1, preload: [:classes])
      %Message{classes: [%Class{}, ...]}

      iex> get_message(999)
      nil

  """
  def get_message(id, opts \\ []) do
    Repo.get(Message, id) |> maybe_preload(opts)
  end

  @doc """
  Gets a single message by ID or raises if not found.

  ## Options

    * `:preload` - list of associations to preload

  ## Examples

      iex> get_message!(1)
      %Message{}

      iex> get_message!(999)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id, opts \\ []) do
    Repo.get!(Message, id) |> maybe_preload(opts)
  end

  @doc """
  Creates a message with the given attributes.

  Returns `{:ok, message}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> create_message(%{name: "My Message", school_id: 1, section_id: 1})
      {:ok, %Message{}}

      iex> create_message(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    section_id = attrs[:section_id] || attrs["section_id"]

    attrs =
      if section_id do
        from(m in Message, where: m.section_id == ^section_id)
        |> set_position_in_attrs(attrs)
      else
        attrs
      end

    %Message{} |> Message.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a message with the given attributes.

  Returns `{:ok, message}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> update_message(message, %{name: "Updated Name"})
      {:ok, %Message{}}

      iex> update_message(message, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message |> Message.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a message.

  Returns `{:ok, message}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

  """
  def delete_message(%Message{} = message), do: Repo.delete(message)

  @doc """
  Returns a changeset for tracking message changes.

  Used for form validation and change tracking.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

      iex> change_message(message, %{name: "New Name"})
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @doc """
  Gets a message by ID and school ID.

  Returns `{:ok, message}` if found, `{:error, :not_found}` otherwise.
  Preloads classes association.

  ## Examples

      iex> get_message_per_school(1, 1)
      {:ok, %Message{}}

      iex> get_message_per_school(999, 1)
      {:error, :not_found}

  """
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
  Gets a section by ID or raises if not found.

  ## Examples

      iex> get_section!(1)
      %Section{}

      iex> get_section!(999)
      ** (Ecto.NoResultsError)

  """
  def get_section!(id), do: Repo.get!(Section, id)

  @doc """
  Gets a section by ID.

  Returns `{:ok, section}` if successful, `{:error, :section_not_found}` otherwise.

  ## Examples

      iex> get_section(1)
      {:ok, %Section{}}

      iex> get_section(999)
      {:error, :section_not_found}

  """
  def get_section(id) do
    case Repo.get(Section, id) do
      nil -> {:error, :section_not_found}
      section -> {:ok, section}
    end
  end

  @doc """
  Gets a section with its messages preloaded and ordered.

  Messages are ordered by position, updated_at, and archived_at.

  ## Examples

      iex> get_section_with_ordered_messages!(1)
      %Section{messages: [%Message{}, ...]}

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
  Gets a section with its messages preloaded and ordered.

  Messages are ordered by position, updated_at, and archived_at.

  Returns `{:ok, section}` if successful, `{:error, :section_not_found}` otherwise.

  ## Examples

      iex> get_section_with_ordered_messages(1)
      {:ok, %Section{messages: [%Message{}, ...]}}

      iex> get_section_with_ordered_messages(999)
      {:error, :section_not_found}

  """
  def get_section_with_ordered_messages(id) do
    messages_query =
      from(
        m in Message,
        order_by: [
          asc: m.position,
          desc: m.updated_at,
          asc: m.archived_at
        ]
      )

    case Repo.get(Section, id) do
      nil -> {:error, :section_not_found}
      section -> {:ok, Repo.preload(section, messages: messages_query)}
    end
  end

  @doc """
  Creates a section with the given attributes.

  Returns `{:ok, section}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> create_section(%{name: "My Section", school_id: 1})
      {:ok, %Section{}}

      iex> create_section(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_section(attrs) do
    school_id = attrs[:school_id] || attrs["school_id"]

    attrs =
      if school_id do
        from(s in Section, where: s.school_id == ^school_id)
        |> set_position_in_attrs(attrs)
      else
        attrs
      end

    %Section{} |> Section.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a section with the given attributes.

  Returns `{:ok, section}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> update_section(section, %{name: "Updated Name"})
      {:ok, %Section{}}

      iex> update_section(section, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_section(%Section{} = section, attrs) do
    section |> Section.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a section.

  Returns `{:ok, section}` if successful, `{:error, changeset}` otherwise.

  ## Examples

      iex> delete_section(section)
      {:ok, %Section{}}

  """
  def delete_section(%Section{} = section), do: Repo.delete(section)

  @doc """
  Returns a changeset for tracking section changes.

  Used for form validation and change tracking.

  ## Examples

      iex> change_section(section)
      %Ecto.Changeset{data: %Section{}}

      iex> change_section(section, %{name: "New Name"})
      %Ecto.Changeset{data: %Section{}}

  """
  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.changeset(section, attrs)
  end

  @doc """
  Updates the position of multiple messages.

  Accepts either a list of message IDs or a list of message structs.
  Positions are assigned based on the order in the list (0-indexed).

  ## Examples

      iex> update_messages_position([3, 1, 2])
      :ok

      iex> update_messages_position([%Message{id: 3}, %Message{id: 1}])
      :ok

  """
  def update_messages_position(messages_or_ids) when is_list(messages_or_ids) do
    ids =
      case messages_or_ids do
        # If it's a list of integers (IDs), use directly
        [id | _] when is_integer(id) -> messages_or_ids
        # If it's a list of structs, extract IDs
        messages -> Enum.map(messages, & &1.id)
      end

    update_positions(Message, ids)
  end

  @doc """
  Updates the position of multiple sections using section structs.

  Positions are assigned based on the order in the list (0-indexed).

  ## Examples

      iex> update_section_position([%Section{id: 2}, %Section{id: 1}])
      :ok

  """
  def update_section_position(sections) when is_list(sections) do
    sections_ids = Enum.map(sections, & &1.id)
    update_positions(Section, sections_ids)
  end

  @doc """
  Updates the position of multiple sections using section IDs.

  Positions are assigned based on the order in the list (0-indexed).

  ## Examples

      iex> update_sections_positions([2, 1, 3])
      :ok

  """
  def update_sections_positions(sections_ids) when is_list(sections_ids),
    do: update_positions(Section, sections_ids)
end
