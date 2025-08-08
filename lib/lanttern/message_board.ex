defmodule Lanttern.MessageBoard do
  @moduledoc """
  The MessageBoard context.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.MessageBoard.Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Schools.Class
  # alias Lanttern.Schools.Student

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
        desc: fragment("CASE WHEN ? THEN 1 ELSE 0 END", m.is_pinned),
        desc: m.inserted_at
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
      where: not is_nil(m.archived_at)
    )
  end

  defp filter_archived(queryable, _) do
    from(
      m in queryable,
      where: is_nil(m.archived_at)
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
        desc: fragment("CASE WHEN ? THEN 1 ELSE 0 END", m.is_pinned),
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
    message
    |> Message.archive_changeset()
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
    message
    |> Message.unarchive_changeset()
    |> Repo.update()
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
        order_by: [
          desc: fragment("CASE WHEN ? THEN 1 ELSE 0 END", m.is_pinned),
          desc: m.inserted_at
        ]
      )
      |> apply_sections_filter_opts(classes_ids: classes_ids, school_id: school_id)
      |> preload([:classes])

    from(s in Section, order_by: s.position)
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
        order_by: [
          desc: fragment("CASE WHEN ? THEN 1 ELSE 0 END", m.is_pinned),
          desc: m.inserted_at
        ]
      )
      |> apply_sections_filter_opts(classes_ids: student_classes_ids, school_id: school_id)

    from(s in Section, order_by: s.position)
    |> preload(messages: ^messages_query)
    |> Repo.all()
  end

  @doc """
  Gets a single section.

  Raises `Ecto.NoResultsError` if the Section does not exist.
  """
  def get_section!(id), do: Repo.get!(Section, id)

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
end
