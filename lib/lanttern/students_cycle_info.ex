defmodule Lanttern.StudentsCycleInfo do
  @moduledoc """
  The StudentsCycleInfo context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Schools.Student
  alias Lanttern.Repo

  alias Lanttern.StudentsCycleInfo.StudentCycleInfo
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Cycle

  @doc """
  Returns the list of students_cycle_info.

  ## Examples

      iex> list_students_cycle_info()
      [%StudentCycleInfo{}, ...]

  """
  def list_students_cycle_info do
    Repo.all(StudentCycleInfo)
  end

  @doc """
  Gets a single student_cycle_info.

  Raises `Ecto.NoResultsError` if the Student cycle info does not exist.

  ## Examples

      iex> get_student_cycle_info!(123)
      %StudentCycleInfo{}

      iex> get_student_cycle_info!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_cycle_info!(id), do: Repo.get!(StudentCycleInfo, id)

  @doc """
  Creates a student_cycle_info.

  ## Examples

      iex> create_student_cycle_info(%{field: value})
      {:ok, %StudentCycleInfo{}}

      iex> create_student_cycle_info(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_cycle_info(attrs \\ %{}) do
    %StudentCycleInfo{}
    |> StudentCycleInfo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_cycle_info.

  ## Examples

      iex> update_student_cycle_info(student_cycle_info, %{field: new_value})
      {:ok, %StudentCycleInfo{}}

      iex> update_student_cycle_info(student_cycle_info, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_cycle_info(%StudentCycleInfo{} = student_cycle_info, attrs) do
    student_cycle_info
    |> StudentCycleInfo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_cycle_info.

  ## Examples

      iex> delete_student_cycle_info(student_cycle_info)
      {:ok, %StudentCycleInfo{}}

      iex> delete_student_cycle_info(student_cycle_info)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_cycle_info(%StudentCycleInfo{} = student_cycle_info) do
    Repo.delete(student_cycle_info)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_cycle_info changes.

  ## Examples

      iex> change_student_cycle_info(student_cycle_info)
      %Ecto.Changeset{data: %StudentCycleInfo{}}

  """
  def change_student_cycle_info(%StudentCycleInfo{} = student_cycle_info, attrs \\ %{}) do
    StudentCycleInfo.changeset(student_cycle_info, attrs)
  end

  @doc """
  List parent cycles with a list of classes related to the given student.

  Results are ordered by cycle end_at desc and cycle start_at asc.

  Classes in tuple are ordered alphabetically.

  ## Examples

      iex> list_cycles_and_classes_for_student(student)
      [{%Cycle{}, [%Class{}, ...]}, ...]

  """
  @spec list_cycles_and_classes_for_student(Student.t()) :: [
          {Cycle.t(), [Class.t()]}
        ]
  def list_cycles_and_classes_for_student(%Student{} = student) do
    student_classes_map =
      from(
        c in Class,
        join: s in assoc(c, :students),
        where: s.id == ^student.id,
        order_by: [asc: c.name]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.cycle_id)

    from(
      cy in Cycle,
      where: cy.school_id == ^student.school_id,
      where: is_nil(cy.parent_cycle_id),
      order_by: [desc: cy.end_at, asc: cy.start_at]
    )
    |> Repo.all()
    |> Enum.map(fn cycle ->
      {cycle, student_classes_map[cycle.id] || []}
    end)
  end
end
