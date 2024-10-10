defmodule Lanttern.NotesLog do
  @moduledoc """
  The NotesLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.NotesLog.NoteLog
  alias Lanttern.Notes.Note

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes()
      [%NoteLog{}, ...]

  """
  def list_notes do
    Repo.all(NoteLog)
  end

  @doc """
  Gets a single note_log.

  Raises `Ecto.NoResultsError` if the Note log does not exist.

  ## Examples

      iex> get_note_log!(123)
      %NoteLog{}

      iex> get_note_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note_log!(id), do: Repo.get!(NoteLog, id)

  @doc """
  Creates a note_log.

  ## Examples

      iex> create_note_log(%{field: value})
      {:ok, %NoteLog{}}

      iex> create_note_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note_log(attrs \\ %{}) do
    %NoteLog{}
    |> NoteLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for create a note log.

  Accepts `{:ok, %Note{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the note or tuple as is. The logging process is handled in an async task.

  ### Options:

  - `:log_operation` – boolean. use `true` to log the operation
  - `:strand_id` – adds type "strand" and the strand_id as type_id
  - `:moment_id` – adds type "moment" and the moment_id as type_id

  """
  @spec maybe_create_note_log(
          {:ok, Note.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_note_log(operation_tuple, operation, opts \\ []) do
    note =
      case operation_tuple do
        {:ok, %Note{} = note} -> note
        _ -> nil
      end

    if note do
      do_create_note_log(
        note,
        operation,
        Keyword.get(opts, :log_operation),
        opts
      )
    end

    operation_tuple
  end

  defp do_create_note_log(
         %Note{} = note,
         operation,
         true,
         opts
       ) do
    attrs =
      note
      |> Map.from_struct()
      |> Map.drop([:id])
      |> Map.put(:note_id, note.id)
      |> Map.put(:operation, operation)
      |> maybe_put_external_id(opts)

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_note_log(attrs)
    end)
  end

  defp do_create_note_log(_, _, nil, _), do: nil

  defp maybe_put_external_id(attrs, []), do: attrs

  defp maybe_put_external_id(attrs, [{:strand_id, strand_id} | opts]) do
    attrs
    |> Map.put(:type, "strand")
    |> Map.put(:type_id, strand_id)
    |> maybe_put_external_id(opts)
  end

  defp maybe_put_external_id(attrs, [{:moment_id, moment_id} | opts]) do
    attrs
    |> Map.put(:type, "moment")
    |> Map.put(:type_id, moment_id)
    |> maybe_put_external_id(opts)
  end

  defp maybe_put_external_id(attrs, [_ | opts]),
    do: maybe_put_external_id(attrs, opts)
end
