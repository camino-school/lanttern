defmodule Lanttern.MessageBoard do
  @moduledoc """
  The MessageBoard context.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Attachments.Attachment
  alias Lanttern.MessageBoard.Message
  alias Lanttern.MessageBoard.MessageAttachment
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Schools.Class

  @doc """
  Returns the list of messages.

  ## Options

  - `:archived` - boolean, if true, returns only archived messages
  - `:school_id` - filters messages by school id
  - `:classes_ids` - filters messages sent to given classes OR to the school. Requires `school_id`.
  - `:preloads` - preloads associated data

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages(opts \\ []) do
    from(
      m in Message,
      group_by: m.id,
      order_by: [
        asc: m.updated_at,
        asc: m.position
      ]
    )
    |> apply_list_messages_opts(opts)
    |> filter_archived(Keyword.get(opts, :archived))
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_messages_opts(queryable, []), do: queryable

  defp apply_list_messages_opts(queryable, [{:school_id, school_id} | opts]) do
    case Keyword.get(opts, :classes_ids) do
      classes_ids when is_list(classes_ids) and classes_ids != [] ->
        from(
          m in queryable,
          left_join: mc in assoc(m, :message_classes),
          where:
            (m.send_to == "school" and m.school_id == ^school_id) or mc.class_id in ^classes_ids
        )

      _ ->
        from(
          m in queryable,
          where: m.school_id == ^school_id
        )
    end
    |> apply_list_messages_opts(opts)
  end

  defp apply_list_messages_opts(queryable, [_ | opts]),
    do: apply_list_messages_opts(queryable, opts)

  defp filter_archived(queryable, true) do
    from(
      m in queryable,
      where: not is_nil(m.archived_at),
      order_by: [asc: m.position, desc: m.updated_at]
    )
  end

  defp filter_archived(queryable, _) do
    from(
      m in queryable,
      where: is_nil(m.archived_at),
      order_by: [asc: m.position, desc: m.updated_at]
    )
  end

  @doc """
  Returns the list of messages related to given student.

  A message is related to the student if it's sent to the student's classes or school.

  ## Examples

      iex> list_student_messages(student)
      [%Message{}, ...]

  """
  @spec list_student_messages(map()) :: [Message.t()]
  def list_student_messages(student) do
    %{id: student_id, school_id: school_id} = student

    student_classes_ids =
      from(
        cl in Class,
        join: cs in "classes_students",
        on: cl.id == cs.class_id,
        where: cs.student_id == ^student_id,
        group_by: cl.id,
        select: cl.id
      )
      |> Repo.all()

    from(
      m in Message,
      left_join: mc in assoc(m, :message_classes),
      where: is_nil(m.archived_at),
      where:
        (m.send_to == "classes" and mc.class_id in ^student_classes_ids) or
          (m.send_to == "school" and m.school_id == ^school_id),
      group_by: m.id,
      order_by: [
        desc: m.inserted_at
      ]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single message.

  Returns `nil` if the Message does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_message(123)
      %Message{}

      iex> get_message(456)
      nil

  """
  def get_message(id, opts \\ []) do
    Repo.get(Message, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single message.

  Same as get_message/1, but raises `Ecto.NoResultsError` if the Message does not exist.

  """
  def get_message!(id, opts \\ []) do
    Repo.get!(Message, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
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

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

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
  Returns the list of sections ordered by position for a specific school.
  """
  def list_sections(school_id) do
    from(s in Section,
      where: s.school_id == ^school_id,
      order_by: s.position
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of sections ordered by position with messages preloaded and filtered.

  ## Parameters

  - `school_id` - the school id for filtering messages
  - `classes_ids` - list of class ids for filtering messages
  """
  def list_sections(school_id, classes_ids) when is_list(classes_ids) do
    messages_query =
      from(
        m in Message,
        where: is_nil(m.archived_at),
        order_by: m.position
      )
      |> apply_sections_filter_opts(classes_ids: classes_ids, school_id: school_id)
      |> preload([:classes])

    from(s in Section,
      where: s.school_id == ^school_id,
      order_by: s.position
    )
    |> preload(messages: ^messages_query)
    |> Repo.all()
  end

  defp apply_sections_filter_opts(queryable, opts) do
    case Keyword.get(opts, :school_id) do
      nil ->
        queryable

      school_id ->
        case Keyword.get(opts, :classes_ids) do
          classes_ids when is_list(classes_ids) and classes_ids != [] ->
            from(
              m in queryable,
              left_join: mc in assoc(m, :message_classes),
              where:
                (m.send_to == "school" and m.school_id == ^school_id) or
                  mc.class_id in ^classes_ids
            )

          _ ->
            from(m in queryable, where: m.school_id == ^school_id)
        end
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
      |> apply_sections_filter_opts(classes_ids: student_classes_ids, school_id: school_id)

    from(s in Section,
      where: s.school_id == ^school_id,
      order_by: s.position
    )
    |> preload(messages: ^messages_query)
    |> Repo.all()
  end

  @doc """
  Gets a single section.

  Raises `Ecto.NoResultsError` if the Section does not exist.
  """
  def get_section!(id), do: Repo.get!(Section, id)

  @doc """
  Gets a single section with messages preloaded and ordered.

  Messages are ordered by position (ascending) and then by updated_at (descending).
  Raises `Ecto.NoResultsError` if the Section does not exist.
  """
  def get_section_with_ordered_messages!(id) do
    Section
    |> Repo.get!(id)
    |> Repo.preload(
      messages:
        from(m in Message,
          order_by: [
            asc: m.position,
            desc: m.updated_at,
            asc: m.archived_at
          ]
        )
    )
  end

  @doc """
  Creates a section.
  """
  def create_section(attrs) do
    %Section{}
    |> Section.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a section.
  """
  def update_section(%Section{} = section, attrs) do
    section
    |> Section.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a section.
  """
  def delete_section(%Section{} = section) do
    Repo.delete(section)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking section changes.
  """
  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.changeset(section, attrs)
  end

  def update_messages_position(messages) do
    messages
    |> Enum.filter(fn m -> is_nil(m.archived_at) end)
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {message, i}, multi ->
      query = from(m in Message, where: m.id == ^message.id)

      Ecto.Multi.update_all(multi, "update-#{message.id}", query, set: [position: i])
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _data} -> :ok
      _ -> {:error, "Something went wrong"}
    end
  end

  def update_section_position(sections) do
    sections
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {section, i}, multi ->
      query = from(m in Section, where: m.id == ^section.id)

      Ecto.Multi.update_all(multi, "update-#{section.id}", query, set: [position: i])
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _data} -> :ok
      _ -> {:error, "Something went wrong"}
    end
  end

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
