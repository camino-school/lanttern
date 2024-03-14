defmodule Lanttern.GradesReports do
  @moduledoc """
  The GradesReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.GradesReports.StudentGradeReportEntry

  @doc """
  Returns the list of student_grade_report_entries.

  ## Examples

      iex> list_student_grade_report_entries()
      [%StudentGradeReportEntry{}, ...]

  """
  def list_student_grade_report_entries do
    Repo.all(StudentGradeReportEntry)
  end

  @doc """
  Gets a single student_grade_report_entry.

  Raises `Ecto.NoResultsError` if the Student grade report entry does not exist.

  ## Examples

      iex> get_student_grade_report_entry!(123)
      %StudentGradeReportEntry{}

      iex> get_student_grade_report_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_grade_report_entry!(id), do: Repo.get!(StudentGradeReportEntry, id)

  @doc """
  Creates a student_grade_report_entry.

  ## Examples

      iex> create_student_grade_report_entry(%{field: value})
      {:ok, %StudentGradeReportEntry{}}

      iex> create_student_grade_report_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_grade_report_entry(attrs \\ %{}) do
    %StudentGradeReportEntry{}
    |> StudentGradeReportEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_grade_report_entry.

  ## Examples

      iex> update_student_grade_report_entry(student_grade_report_entry, %{field: new_value})
      {:ok, %StudentGradeReportEntry{}}

      iex> update_student_grade_report_entry(student_grade_report_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_grade_report_entry(%StudentGradeReportEntry{} = student_grade_report_entry, attrs) do
    student_grade_report_entry
    |> StudentGradeReportEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_grade_report_entry.

  ## Examples

      iex> delete_student_grade_report_entry(student_grade_report_entry)
      {:ok, %StudentGradeReportEntry{}}

      iex> delete_student_grade_report_entry(student_grade_report_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_grade_report_entry(%StudentGradeReportEntry{} = student_grade_report_entry) do
    Repo.delete(student_grade_report_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_grade_report_entry changes.

  ## Examples

      iex> change_student_grade_report_entry(student_grade_report_entry)
      %Ecto.Changeset{data: %StudentGradeReportEntry{}}

  """
  def change_student_grade_report_entry(%StudentGradeReportEntry{} = student_grade_report_entry, attrs \\ %{}) do
    StudentGradeReportEntry.changeset(student_grade_report_entry, attrs)
  end
end
