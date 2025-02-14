defmodule Lanttern.MessageBoard do
  @moduledoc """
  The MessageBoard context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.MessageBoard.Message

  @doc """
  Returns the list of messages.

  ## Options

  - `:archived` - boolean, if true, returns only archived messages
  - `:school_id` - filters messages by school id
  - `:classes_ids` - filters messages by given classes
  - `:preloads` - preloads associated data

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages(opts \\ []) do
    from(
      m in Message,
      order_by: [desc: m.inserted_at]
    )
    |> apply_list_messages_opts(opts)
    |> filter_archived(Keyword.get(opts, :archived))
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_messages_opts(queryable, []), do: queryable

  defp apply_list_messages_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      m in queryable,
      where: m.school_id == ^school_id
    )
    |> apply_list_messages_opts(opts)
  end

  defp apply_list_messages_opts(queryable, [{:classes_ids, classes_ids} | opts])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      m in queryable,
      join: mc in assoc(m, :message_classes),
      where: mc.class_id in ^classes_ids
    )
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
end
