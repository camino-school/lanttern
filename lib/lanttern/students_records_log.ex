defmodule Lanttern.StudentsRecordsLog do
  @moduledoc """
  The StudentsRecordsLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.StudentsRecordsLog.StudentRecordLog

  @doc """
  Creates a student_record_log.

  ## Examples

      iex> create_student_record_log(%{field: value})
      {:ok, %StudentRecordLog{}}

      iex> create_student_record_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_log(attrs \\ %{}) do
    %StudentRecordLog{}
    |> StudentRecordLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for create a student record log.

  Accepts `{:ok, %StudentRecord{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the note or tuple as is. The logging process is handled in an async task.

  ### Options:

  - `:log_profile_id` – the profile id used to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_student_record_log(
          {:ok, StudentRecord.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, StudentRecord.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_student_record_log(operation_tuple, operation, opts \\ [])

  def maybe_create_student_record_log({:error, _} = operation_tuple, _, _), do: operation_tuple

  def maybe_create_student_record_log(
        {:ok, %StudentRecord{} = student_record} = operation_tuple,
        operation,
        opts
      ) do
    case Keyword.get(opts, :log_profile_id) do
      profile_id when not is_nil(profile_id) ->
        do_create_student_record_log(student_record, operation, profile_id)
        operation_tuple

      _ ->
        operation_tuple
    end
  end

  defp do_create_student_record_log(student_record, operation, profile_id) do
    attrs =
      student_record
      |> Map.from_struct()
      |> Map.put(:student_record_id, student_record.id)
      |> Map.put(:profile_id, profile_id)
      |> Map.put(:operation, operation)

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_student_record_log(attrs)
    end)
  end
end
