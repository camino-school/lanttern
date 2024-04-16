defmodule Lanttern.AssessmentsLog do
  @moduledoc """
  The AssessmentsLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.AssessmentsLog.AssessmentPointEntryLog

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
end
