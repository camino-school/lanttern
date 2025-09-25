defmodule Lanttern.MessageBoardV2 do
  @moduledoc """
  The MessageBoardV2 context - Version 2

  This module uses the new MessageV2 schema and messages_classes_v2 relationships.
  It's designed to work alongside the original MessageBoard during the migration period.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.MessageBoard.MessageV2, as: Message
  alias Lanttern.MessageBoard.Section

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
end
