defmodule Lanttern.AssessmentsLog do
  @moduledoc """
  The AssessmentsLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.AssessmentsLog.AssessmentPointEntryLog
  alias Lanttern.Assessments.AssessmentPointEntry

  @doc """
  Returns the list of assessment_point_entries logs.

  ## Examples

      iex> list_assessment_point_entries_logs()
      [%AssessmentPointEntryLog{}, ...]

  """
  def list_assessment_point_entries_logs do
    Repo.all(AssessmentPointEntryLog)
  end

  @doc """
  Gets a single assessment_point_entry log.

  Raises `Ecto.NoResultsError` if the Assessment point entry does not exist.

  ## Examples

      iex> get_assessment_point_entry_log!(123)
      %AssessmentPointEntryLog{}

      iex> get_assessment_point_entry_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point_entry_log!(id), do: Repo.get!(AssessmentPointEntryLog, id)

  @doc """
  Creates a assessment_point_entry log.

  ## Examples

      iex> create_assessment_point_entry_log(%{field: value})
      {:ok, %AssessmentPointEntryLog{}}

      iex> create_assessment_point_entry_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_entry_log(attrs \\ %{}) do
    %AssessmentPointEntryLog{}
    |> AssessmentPointEntryLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for create a assessment_point_entry log.

  Accepts `{:ok, %AssessmentPointEntry{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the entry or tuple as is. The log are handled in an async task.
  """
  @spec maybe_create_assessment_point_entry_log(
          {:ok, AssessmentPointEntry.t()} | {:error, Ecto.Changeset.t()},
          String.t(),
          Keyword.t()
        ) ::
          {:ok, AssessmentPointEntry.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_assessment_point_entry_log(operation_tuple, operation, opts \\ []) do
    entry =
      case operation_tuple do
        {:ok, %AssessmentPointEntry{} = entry} -> entry
        _ -> nil
      end

    if entry do
      do_create_assessment_point_entry_log(
        entry,
        operation,
        Keyword.get(opts, :log_profile_id)
      )
    end

    operation_tuple
  end

  defp do_create_assessment_point_entry_log(_, _, nil), do: nil

  defp do_create_assessment_point_entry_log(
         %AssessmentPointEntry{} = entry,
         operation,
         profile_id
       ) do
    attrs =
      entry
      |> Map.from_struct()
      |> Map.drop([:id])
      |> Map.put(:assessment_point_entry_id, entry.id)
      |> Map.put(:operation, operation)
      |> Map.put(:profile_id, profile_id)

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_assessment_point_entry_log(attrs)
    end)
  end
end
