defmodule Lanttern.MessageBoard do
  @moduledoc """
  The MessageBoard context.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.MessageBoard.Message
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Student

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
  @spec list_student_messages(Student.t()) :: [Message.t()]
  def list_student_messages(%Student{} = student) do
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

  alias Lanttern.MessageBoard.CardSection

  @doc """
  Returns the list of card_sections.
  """
  def list_card_sections do
    CardSection
    |> preload(:messages)
    |> Repo.all()
  end

  @doc """
  Gets a single card_section.

  Raises `Ecto.NoResultsError` if the Card section does not exist.
  """
  def get_card_section!(id), do: Repo.get!(CardSection, id)

  @doc """
  Creates a card_section.
  """
  def create_card_section(attrs \\ %{}) do
    %CardSection{}
    |> CardSection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a card_section.
  """
  def update_card_section(%CardSection{} = card_section, attrs) do
    card_section
    |> CardSection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a card_section.
  """
  def delete_card_section(%CardSection{} = card_section) do
    Repo.delete(card_section)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking card_section changes.
  """
  def change_card_section(%CardSection{} = card_section, attrs \\ %{}) do
    CardSection.changeset(card_section, attrs)
  end

  alias Lanttern.MessageBoard.CardMessage

  @doc """
  Returns the list of card_messages.
  """
  def list_card_messages do
    Repo.all(CardMessage)
  end

  @doc """
  Gets a single card_message.

  Raises `Ecto.NoResultsError` if the Card message does not exist.
  """
  def get_card_message!(id), do: Repo.get!(CardMessage, id)

  @doc """
  Creates a card_message.
  """
  def create_card_message(attrs \\ %{}) do
    %CardMessage{}
    |> CardMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a card_message.
  """
  def update_card_message(%CardMessage{} = card_message, attrs) do
    card_message
    |> CardMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a card_message.
  """
  def delete_card_message(%CardMessage{} = card_message) do
    Repo.delete(card_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking card_message changes.
  """
  def change_card_message(%CardMessage{} = card_message, attrs \\ %{}) do
    CardMessage.changeset(card_message, attrs)
  end
end
