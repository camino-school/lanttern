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
  Gets a single student_record_report_ai_config by school_id.

  Returns `nil` if the Student record report ai config does not exist.

  ## Examples

      iex> get_student_record_report_ai_config_by_school_id(123)
      %StudentRecordReportAIConfig{}

      iex> get_student_record_report_ai_config_by_school_id(456)
      nil

  """
  def get_student_record_report_ai_config_by_school_id(school_id),
    do: Repo.get_by(StudentRecordReportAIConfig, school_id: school_id)

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

  alias Lanttern.StudentRecordReports.StudentRecordReport

  @doc """
  Returns the list of student_record_reports.

  ## Examples

      iex> list_student_record_reports()
      [%StudentRecordReport{}, ...]

  """
  def list_student_record_reports do
    Repo.all(StudentRecordReport)
  end

  @doc """
  Gets a single student_record_report.

  Raises `Ecto.NoResultsError` if the Student record report does not exist.

  ## Examples

      iex> get_student_record_report!(123)
      %StudentRecordReport{}

      iex> get_student_record_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_report!(id), do: Repo.get!(StudentRecordReport, id)

  @doc """
  Creates a student_record_report.

  ## Examples

      iex> create_student_record_report(%{description: value, student_id: value})
      {:ok, %StudentRecordReport{}}

      iex> create_student_record_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_report(attrs \\ %{}) do
    %StudentRecordReport{}
    |> StudentRecordReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_report.

  ## Examples

      iex> update_student_record_report(student_record_report, %{description: new_value, student_id: value})
      {:ok, %StudentRecordReport{}}

      iex> update_student_record_report(student_record_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_report(%StudentRecordReport{} = student_record_report, attrs) do
    student_record_report
    |> StudentRecordReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_report.

  ## Examples

      iex> delete_student_record_report(student_record_report)
      {:ok, %StudentRecordReport{}}

      iex> delete_student_record_report(student_record_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_report(%StudentRecordReport{} = student_record_report) do
    Repo.delete(student_record_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_report changes.

  ## Examples

      iex> change_student_record_report(student_record_report)
      %Ecto.Changeset{data: %StudentRecordReport{}}

  """
  def change_student_record_report(%StudentRecordReport{} = student_record_report, attrs \\ %{}) do
    StudentRecordReport.changeset(student_record_report, attrs)
  end
end
