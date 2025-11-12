defmodule Lanttern.MessageBoardV2 do
  @moduledoc """
  The MessageBoardV2 context - Version 2
  """
  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers

  alias Lanttern.Attachments.Attachment
  alias Lanttern.MessageBoard.MessageAttachment
  alias Lanttern.MessageBoard.MessageV2, as: Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Repo
  alias Lanttern.Schools.Class

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
    * `:school_id` - filter by school ID (for multi-tenant security)

  ## Examples

      iex> get_message(1)
      %Message{}

      iex> get_message(1, preload: [:classes])
      %Message{classes: [%Class{}, ...]}

      iex> get_message(1, school_id: 1)
      %Message{}

      iex> get_message(999)
      nil

  """
  def get_message(id, opts \\ []) do
    Message
    |> apply_message_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_message_opts(queryable, []), do: queryable

  defp apply_message_opts(queryable, [{:school_id, school_id} | opts]) do
    from(m in queryable, where: m.school_id == ^school_id)
    |> apply_message_opts(opts)
  end

  defp apply_message_opts(queryable, [_opt | opts]) do
    apply_message_opts(queryable, opts)
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
      from(m in Message, where: m.section_id == ^section_id)
      |> set_position_in_attrs(attrs)

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
  Archive a message.

  Kind of a soft delete, using the `archived_at` field.

  ## Examples

      iex> archive_message(message)
      {:ok, %Message{}}

      iex> archive_message(message)
      {:error, %Ecto.Changeset{}}

  """
  @spec archive_message(Message.t()) ::
          {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def archive_message(%Message{} = message) do
    total_messages =
      from(m in Message,
        where: m.section_id == ^message.section_id,
        select: count(m.id)
      )
      |> Repo.one()

    max_archived_position =
      from(m in Message,
        where: m.section_id == ^message.section_id and not is_nil(m.archived_at),
        select: max(m.position)
      )
      |> Repo.one()

    new_position =
      case max_archived_position do
        nil -> total_messages
        max_pos -> max_pos + 1
      end

    message
    |> Message.archive_changeset()
    |> Ecto.Changeset.put_change(:position, new_position)
    |> Repo.update()
  end

  @doc """
  Unarchive a message.

  Sets `archived_at` field to nil.

  ## Examples

  iex> unarchive_message(message)
  {:ok, %StaffMember{}}

  iex> unarchive_message(message)
  {:error, %Ecto.Changeset{}}

  """
  @spec unarchive_message(Message.t()) ::
          {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def unarchive_message(%Message{} = message) do
    non_archived_count = count_non_archived_messages_in_section(message.section_id)

    message
    |> Message.unarchive_changeset()
    |> Ecto.Changeset.put_change(:position, non_archived_count + 1)
    |> Repo.update()
  end

  @doc """
  Counts non-archived messages in a section.
  Returns 0 if section_id is nil.
  """
  def count_non_archived_messages_in_section(nil), do: 0

  def count_non_archived_messages_in_section(section_id) do
    from(m in Message,
      where: m.section_id == ^section_id and is_nil(m.archived_at),
      select: count(m.id)
    )
    |> Repo.one()
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
  Lists sections with messages filtered by student.

  A message is related to the student if it's sent to the student's classes or school.
  Returns sections with their associated messages filtered by student access.
  """
  def list_sections_for_students(student_id, school_id) do
    student_classes_ids =
      from(
        cl in Class,
        join: cs in "classes_students",
        on: cl.id == cs.class_id,
        where: cs.student_id == ^student_id,
        select: cl.id
      )
      |> Repo.all()

    messages_query =
      from(
        m in Message,
        left_join: mc in assoc(m, :message_classes),
        where: is_nil(m.archived_at),
        order_by: m.position
      )
      |> apply_section_opts(classes_ids: student_classes_ids, school_id: school_id)

    from(s in Section,
      where: s.school_id == ^school_id,
      order_by: s.position
    )
    |> preload(messages: ^messages_query)
    |> Repo.all()
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

  Returns the section or `nil` if not found.

  ## Options

    * `:preloads` - List of associations to preload
    * `:school_id` - Filter by school ID (for multi-tenant security)

  ## Examples

      iex> get_section(1)
      %Section{}

      iex> get_section(1, preloads: :messages)
      %Section{messages: [%Message{}, ...]}

      iex> get_section(1, school_id: 1)
      %Section{}

      iex> get_section(1, school_id: 1, preloads: :messages)
      %Section{messages: [%Message{}, ...]}

      iex> get_section(999)
      nil

      # Returns nil if section doesn't belong to the specified school
      iex> get_section(1, school_id: 999)
      nil

  """
  def get_section(id, opts \\ []) do
    Section
    |> apply_section_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_section_opts(queryable, []), do: queryable

  defp apply_section_opts(queryable, [{:school_id, school_id} | opts]) do
    from(s in queryable, where: s.school_id == ^school_id)
    |> apply_section_opts(opts)
  end

  defp apply_section_opts(queryable, [{:preloads, _preloads} | opts]) do
    # Skip preloads here, handled by maybe_preload
    apply_section_opts(queryable, opts)
  end

  defp apply_section_opts(queryable, [_ | opts]),
    do: apply_section_opts(queryable, opts)

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
      from(s in Section, where: s.school_id == ^school_id)
      |> set_position_in_attrs(attrs)

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

  # @doc """
  # Returns the list of message_attachments.

  # ## Examples

  #     iex> list_message_attachments()
  #     [%MessageAttachment{}, ...]

  # """
  def list_message_attachments do
    Repo.all(MessageAttachment)
  end

  # @doc """
  # Gets a single message_attachment.

  # Raises `Ecto.NoResultsError` if the Message attachment does not exist.

  # ## Examples

  #     iex> get_message_attachment!(123)
  #     %MessageAttachment{}

  #     iex> get_message_attachment!(456)
  #     ** (Ecto.NoResultsError)

  # """
  def get_message_attachment!(id), do: Repo.get!(MessageAttachment, id)

  @doc """
  Creates a message_attachment.
  """
  @spec create_message_attachment(pos_integer(), pos_integer(), map()) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def create_message_attachment(profile_id, message_id, attrs) do
    insert_query =
      %Attachment{}
      |> Attachment.changeset(Map.put(attrs, "owner_id", profile_id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_attachment, insert_query)
    |> Ecto.Multi.run(:set_position, fn _repo, %{insert_attachment: attachment} ->
      from(
        ma in MessageAttachment,
        where: ma.message_id == ^message_id
      )
      |> set_position_in_attrs(%{
        message_id: message_id,
        attachment_id: attachment.id,
        owner_id: profile_id
      })
      |> then(&{:ok, &1})
    end)
    |> Ecto.Multi.insert(:link_message, fn %{set_position: attrs} ->
      MessageAttachment.changeset(%MessageAttachment{}, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{insert_attachment: attachment}} -> {:ok, attachment}
    end
  end

  @doc """
  Update message attachments positions based on ids list order.

  Expects a list of attachment ids in the new order.
  """
  @spec update_message_attachments_positions(attachments_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_message_attachments_positions(attachments_ids),
    do: update_positions(MessageAttachment, attachments_ids, id_field: :attachment_id)
end
