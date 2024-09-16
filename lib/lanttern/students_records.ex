defmodule Lanttern.StudentsRecords do
  @moduledoc """
  The StudentsRecords context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.StudentsRecords.StudentRecord

  @doc """
  Returns the list of students_records.

  ## Examples

      iex> list_students_records()
      [%StudentRecord{}, ...]

  """
  def list_students_records do
    Repo.all(StudentRecord)
  end

  @doc """
  Gets a single student_record.

  Raises `Ecto.NoResultsError` if the Student record does not exist.

  ## Examples

      iex> get_student_record!(123)
      %StudentRecord{}

      iex> get_student_record!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record!(id), do: Repo.get!(StudentRecord, id)

  @doc """
  Creates a student_record.

  ## Examples

      iex> create_student_record(%{field: value})
      {:ok, %StudentRecord{}}

      iex> create_student_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record(attrs \\ %{}) do
    %StudentRecord{}
    |> StudentRecord.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record.

  ## Examples

      iex> update_student_record(student_record, %{field: new_value})
      {:ok, %StudentRecord{}}

      iex> update_student_record(student_record, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record(%StudentRecord{} = student_record, attrs) do
    student_record
    |> StudentRecord.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record.

  ## Examples

      iex> delete_student_record(student_record)
      {:ok, %StudentRecord{}}

      iex> delete_student_record(student_record)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record(%StudentRecord{} = student_record) do
    Repo.delete(student_record)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record changes.

  ## Examples

      iex> change_student_record(student_record)
      %Ecto.Changeset{data: %StudentRecord{}}

  """
  def change_student_record(%StudentRecord{} = student_record, attrs \\ %{}) do
    StudentRecord.changeset(student_record, attrs)
  end
end
