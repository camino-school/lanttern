defmodule Lanttern.StudentsCycleInfoLog do
  @moduledoc """
  The StudentsCycleInfoLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.StudentsCycleInfo.StudentCycleInfo
  alias Lanttern.StudentsCycleInfoLog.StudentCycleInfoLog

  @doc """
  Creates a student_cycle_info_log.

  ## Examples

      iex> create_student_cycle_info_log(%{field: value})
      {:ok, %StudentCycleInfoLog{}}

      iex> create_student_cycle_info_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_cycle_info_log(attrs \\ %{}) do
    %StudentCycleInfoLog{}
    |> StudentCycleInfoLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for create a student cycle info log.

  Accepts `{:ok, %StudentCycleInfo{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the note or tuple as is. The logging process is handled in an async task.

  ### Options:

  - `:log_profile_id` – the profile id used to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_student_cycle_info_log(
          {:ok, StudentCycleInfo.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, StudentCycleInfo.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_student_cycle_info_log(operation_tuple, operation, opts \\ [])

  def maybe_create_student_cycle_info_log({:error, _} = operation_tuple, _, _),
    do: operation_tuple

  def maybe_create_student_cycle_info_log(
        {:ok, %StudentCycleInfo{} = student_cycle_info} = operation_tuple,
        operation,
        opts
      ) do
    case Keyword.get(opts, :log_profile_id) do
      profile_id when not is_nil(profile_id) ->
        do_create_student_cycle_info_log(student_cycle_info, operation, profile_id)
        operation_tuple

      _ ->
        operation_tuple
    end
  end

  defp do_create_student_cycle_info_log(student_cycle_info, operation, profile_id) do
    attrs =
      student_cycle_info
      |> Map.from_struct()
      |> Map.put(:student_cycle_info_id, student_cycle_info.id)
      |> Map.put(:profile_id, profile_id)
      |> Map.put(:operation, operation)

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_student_cycle_info_log(attrs)
    end)
  end
end
