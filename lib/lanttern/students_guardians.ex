defmodule Lanttern.StudentsGuardians do
  @moduledoc """
  The StudentsGuardians context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Schools.Guardian
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of students_guardians.

  ## Examples

      iex> list_students_guardians()
      [%Guardian{}, ...]

  """
  def list_students_guardians do
    Repo.all(Guardian)
  end

  @doc """
  Gets a single guardian.

  Raises `Ecto.NoResultsError` if the Guardian does not exist.

  ## Examples

      iex> get_guardian!(123)
      %Guardian{}

      iex> get_guardian!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guardian!(id), do: Repo.get!(Guardian, id)

  @doc """
  Gets guardians for a given student.

  ## Examples

      iex> get_guardians_for_student(current_user, student)
      [%Guardian{}, ...]

  """
  def get_guardians_for_student(current_user, %Student{} = student) do
    user_school_id = current_user.current_profile.school_id

    if student.school_id == user_school_id do
      Repo.all(
        from g in Guardian,
          join: sg in "students_guardians",
          on: g.id == sg.guardian_id,
          where: sg.student_id == ^student.id,
          select: g
      )
    else
      []
    end
  end

  @doc """
  Associates a guardian to a student.

  ## Examples

      iex> add_guardian_to_student(current_user, student, guardian)
      {:ok, %Student{}}

  """
  def add_guardian_to_student(current_user, %Student{} = student, %Guardian{} = guardian) do
    user_school_id = current_user.current_profile.school_id

    if student.school_id == user_school_id && guardian.school_id == user_school_id do
      student
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:guardians, (student.guardians || []) ++ [guardian])
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Removes a guardian from a student.

  ## Examples

      iex> remove_guardian_from_student(current_user, student, guardian_id)
      {:ok, %Student{}}

  """
  def remove_guardian_from_student(current_user, %Student{} = student, guardian_id) do
    user_school_id = current_user.current_profile.school_id

    if student.school_id == user_school_id do
      student
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(
        :guardians,
        Enum.reject(student.guardians, &(&1.id == guardian_id))
      )
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end
end
