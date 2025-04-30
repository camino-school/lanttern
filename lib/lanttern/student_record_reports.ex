defmodule Lanttern.StudentRecordReports do
  @moduledoc """
  The StudentRecordReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.StudentRecordReports.StudentRecordReportAIConfig

  @doc """
  Returns the list of student_record_report_ai_config.

  ## Examples

      iex> list_student_record_report_ai_config()
      [%StudentRecordReportAIConfig{}, ...]

  """
  def list_student_record_report_ai_config do
    Repo.all(StudentRecordReportAIConfig)
  end

  @doc """
  Gets a single student_record_report_ai_config.

  Raises `Ecto.NoResultsError` if the Student record report ai config does not exist.

  ## Examples

      iex> get_student_record_report_ai_config!(123)
      %StudentRecordReportAIConfig{}

      iex> get_student_record_report_ai_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_report_ai_config!(id), do: Repo.get!(StudentRecordReportAIConfig, id)

  @doc """
  Creates a student_record_report_ai_config.

  ## Examples

      iex> create_student_record_report_ai_config(%{field: value})
      {:ok, %StudentRecordReportAIConfig{}}

      iex> create_student_record_report_ai_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_report_ai_config(attrs \\ %{}) do
    %StudentRecordReportAIConfig{}
    |> StudentRecordReportAIConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_report_ai_config.

  ## Examples

      iex> update_student_record_report_ai_config(student_record_report_ai_config, %{field: new_value})
      {:ok, %StudentRecordReportAIConfig{}}

      iex> update_student_record_report_ai_config(student_record_report_ai_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config,
        attrs
      ) do
    student_record_report_ai_config
    |> StudentRecordReportAIConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_report_ai_config.

  ## Examples

      iex> delete_student_record_report_ai_config(student_record_report_ai_config)
      {:ok, %StudentRecordReportAIConfig{}}

      iex> delete_student_record_report_ai_config(student_record_report_ai_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config
      ) do
    Repo.delete(student_record_report_ai_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_report_ai_config changes.

  ## Examples

      iex> change_student_record_report_ai_config(student_record_report_ai_config)
      %Ecto.Changeset{data: %StudentRecordReportAIConfig{}}

  """
  def change_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config,
        attrs \\ %{}
      ) do
    StudentRecordReportAIConfig.changeset(student_record_report_ai_config, attrs)
  end
end
