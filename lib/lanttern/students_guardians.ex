defmodule Lanttern.StudentsGuardians do
  @moduledoc """
  The StudentsGuardians context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Schools.Guardian
  alias Lanttern.Schools.Student

  @doc """
  Gets students for a given guardian.

  ## Examples

      iex> get_students_for_guardian(scope, guardian)
      [%Student{}, ...]

  """
  def get_students_for_guardian(scope, %Guardian{} = guardian) do
    if guardian.school_id == scope.school_id && has_permission?(scope, "school_management") do
      Repo.all(
        from s in Student,
          join: sg in "students_guardians",
          on: s.id == sg.student_id,
          where: sg.guardian_id == ^guardian.id,
          select: s
      )
    else
      []
    end
  end

  @doc """
  Gets guardians for a given student.

  ## Examples

      iex> get_guardians_for_student(scope, student)
      [%Guardian{}, ...]

  """
  def get_guardians_for_student(scope, %Student{} = student) do
    if student.school_id == scope.school_id && has_permission?(scope, "school_management") do
      Repo.all(
        from g in Guardian,
          join: sg in "students_guardians",
          on: g.id == sg.guardian_id,
          where: sg.student_id == ^student.id and sg.school_id == ^scope.school_id,
          select: g
      )
    else
      []
    end
  end

  @doc """
  Associates a guardian to a student.

  ## Examples

      iex> add_guardian_to_student(scope, student, guardian)
      {:ok, :created}

  """
  def add_guardian_to_student(scope, %Student{} = student, %Guardian{} = guardian) do
    if student.school_id == scope.school_id && guardian.school_id == scope.school_id &&
         has_permission?(scope, "school_management") do
      existing_association =
        Repo.one(
          from sg in "students_guardians",
            where: sg.student_id == ^student.id and sg.guardian_id == ^guardian.id,
            select: 1
        )

      case existing_association do
        nil ->
          {1, _} =
            Repo.insert_all(
              "students_guardians",
              [%{student_id: student.id, guardian_id: guardian.id}]
            )

          {:ok, :created}

        _ ->
          {:ok, :already_exists}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Removes a guardian from a student.

  ## Examples

      iex> remove_guardian_from_student(scope, student, guardian_id)
      {:ok, :deleted}

  """
  def remove_guardian_from_student(scope, %Student{} = student, guardian_id) do
    if student.school_id == scope.school_id && has_permission?(scope, "school_management") do
      # Delete directly from join table
      {count, _} =
        Repo.delete_all(
          from sg in "students_guardians",
            where: sg.student_id == ^student.id and sg.guardian_id == ^guardian_id
        )

      case count do
        0 -> {:ok, :not_found}
        _ -> {:ok, :deleted}
      end
    else
      {:error, :unauthorized}
    end
  end

  defp has_permission?(scope, permission) do
    permission in scope.permissions
  end
end
