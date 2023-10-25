defmodule Lanttern.Schools do
  @moduledoc """
  The Schools context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Student
  alias Lanttern.Schools.Teacher
  alias Lanttern.Identity

  @doc """
  Returns the list of schools.

  ## Examples

      iex> list_schools()
      [%School{}, ...]

  """
  def list_schools do
    Repo.all(School)
  end

  @doc """
  Gets a single school.

  Raises `Ecto.NoResultsError` if the School does not exist.

  ## Examples

      iex> get_school!(123)
      %School{}

      iex> get_school!(456)
      ** (Ecto.NoResultsError)

  """
  def get_school!(id), do: Repo.get!(School, id)

  @doc """
  Creates a school.

  ## Examples

      iex> create_school(%{field: value})
      {:ok, %School{}}

      iex> create_school(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_school(attrs \\ %{}) do
    %School{}
    |> School.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a school.

  ## Examples

      iex> update_school(school, %{field: new_value})
      {:ok, %School{}}

      iex> update_school(school, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_school(%School{} = school, attrs) do
    school
    |> School.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a school.

  ## Examples

      iex> delete_school(school)
      {:ok, %School{}}

      iex> delete_school(school)
      {:error, %Ecto.Changeset{}}

  """
  def delete_school(%School{} = school) do
    Repo.delete(school)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking school changes.

  ## Examples

      iex> change_school(school)
      %Ecto.Changeset{data: %School{}}

  """
  def change_school(%School{} = school, attrs \\ %{}) do
    School.changeset(school, attrs)
  end

  @doc """
  Returns the list of classes.

  ### Options:

  `:preloads` – preloads associated data
  `:schools_ids` – filter classes by schools

  ## Examples

      iex> list_classes()
      [%Class{}, ...]

  """
  def list_classes(opts \\ []) do
    Class
    |> maybe_filter_classes_by_schools(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_classes_by_schools(classes_query, opts) do
    case Keyword.get(opts, :schools_ids) do
      nil ->
        classes_query

      schools_ids ->
        from(
          c in classes_query,
          where: c.school_id in ^schools_ids
        )
    end
  end

  @doc """
  Gets a single class.

  Raises `Ecto.NoResultsError` if the Class does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_class!(123)
      %Class{}

      iex> get_class!(456)
      ** (Ecto.NoResultsError)

  """
  def get_class!(id, opts \\ []) do
    Repo.get!(Class, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a class.

  ## Examples

      iex> create_class(%{field: value})
      {:ok, %Class{}}

      iex> create_class(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_class(attrs \\ %{}) do
    %Class{}
    |> Class.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a class.

  ## Examples

      iex> update_class(class, %{field: new_value})
      {:ok, %Class{}}

      iex> update_class(class, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_class(%Class{} = class, attrs) do
    class
    |> Repo.preload(:students)
    |> Class.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a class.

  ## Examples

      iex> delete_class(class)
      {:ok, %Class{}}

      iex> delete_class(class)
      {:error, %Ecto.Changeset{}}

  """
  def delete_class(%Class{} = class) do
    Repo.delete(class)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking class changes.

  ## Examples

      iex> change_class(class)
      %Ecto.Changeset{data: %Class{}}

  """
  def change_class(%Class{} = class, attrs \\ %{}) do
    Class.changeset(class, attrs)
  end

  @doc """
  Returns the list of students.

  ### Options:

  `:preloads` – preloads associated data
  `:classes_ids` – filter students by provided list of ids

  ## Examples

      iex> list_students()
      [%Student{}, ...]

  """
  def list_students(opts \\ []) do
    Student
    |> maybe_filter_students_by_class(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_students_by_class(student_query, opts) do
    case Keyword.get(opts, :classes_ids) do
      nil ->
        student_query

      classes_ids ->
        from(
          s in student_query,
          join: c in assoc(s, :classes),
          where: c.id in ^classes_ids
        )
    end
  end

  @doc """
  Gets a single student.

  Raises `Ecto.NoResultsError` if the Student does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_student!(123)
      %Student{}

      iex> get_student!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student!(id, opts \\ []) do
    Repo.get!(Student, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student.

  ## Examples

      iex> create_student(%{field: value})
      {:ok, %Student{}}

      iex> create_student(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student(attrs \\ %{}) do
    %Student{}
    |> Student.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student.

  ## Examples

      iex> update_student(student, %{field: new_value})
      {:ok, %Student{}}

      iex> update_student(student, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student(%Student{} = student, attrs) do
    student
    |> Repo.preload(:classes)
    |> Student.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student.

  ## Examples

      iex> delete_student(student)
      {:ok, %Student{}}

      iex> delete_student(student)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student(%Student{} = student) do
    Repo.delete(student)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student changes.

  ## Examples

      iex> change_student(student)
      %Ecto.Changeset{data: %Student{}}

  """
  def change_student(%Student{} = student, attrs \\ %{}) do
    Student.changeset(student, attrs)
  end

  @doc """
  Returns the list of teachers.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_teachers()
      [%Teacher{}, ...]

  """
  def list_teachers(opts \\ []) do
    Teacher
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single teacher.

  Raises `Ecto.NoResultsError` if the Teacher does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_teacher!(123)
      %Teacher{}

      iex> get_teacher!(456)
      ** (Ecto.NoResultsError)

  """
  def get_teacher!(id, opts \\ []) do
    Repo.get!(Teacher, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a teacher.

  ## Examples

      iex> create_teacher(%{field: value})
      {:ok, %Teacher{}}

      iex> create_teacher(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_teacher(attrs \\ %{}) do
    %Teacher{}
    |> Teacher.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a teacher.

  ## Examples

      iex> update_teacher(teacher, %{field: new_value})
      {:ok, %Teacher{}}

      iex> update_teacher(teacher, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_teacher(%Teacher{} = teacher, attrs) do
    teacher
    |> Teacher.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a teacher.

  ## Examples

      iex> delete_teacher(teacher)
      {:ok, %Teacher{}}

      iex> delete_teacher(teacher)
      {:error, %Ecto.Changeset{}}

  """
  def delete_teacher(%Teacher{} = teacher) do
    Repo.delete(teacher)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking teacher changes.

  ## Examples

      iex> change_teacher(teacher)
      %Ecto.Changeset{data: %Teacher{}}

  """
  def change_teacher(%Teacher{} = teacher, attrs \\ %{}) do
    Teacher.changeset(teacher, attrs)
  end

  @doc """
  Create students, classes, users, and profiles based on CSV data.

  It returns a tuple with the `csv_student` as the first item,
  and a nested `:ok` or `:error` tuple, with the created student or an error message.

  ### User and profile creation

  If there's no email in the CSV row, user and profile creation is skipped.

  If a user with the email already exists, we create a student profile linked to this user.

  Else, we create a user with the student email and a linked student profile.

  ## Examples

      iex> create_students_from_csv(csv_students, class_name_id_map, school_id)
      [{csv_student, {:ok, "Student and user profile created"}}, ...]

  """
  def create_students_from_csv(csv_students, class_name_id_map, school_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:classes, fn _repo, _changes ->
      insert_and_get_all_classes(class_name_id_map, school_id)
    end)
    |> Ecto.Multi.run(:students, fn _repo, changes ->
      insert_students(changes, csv_students, school_id)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes.students}
      error_tuple -> error_tuple
    end
  end

  defp insert_and_get_all_classes(class_name_id_map, school_id) do
    new_classes =
      class_name_id_map
      |> Enum.filter(fn {_csv_class_name, class_id} -> class_id == "" end)
      |> Enum.map(fn {csv_class_name, _} ->
        %{
          name: csv_class_name,
          school_id: school_id,
          inserted_at: naive_timestamp(),
          updated_at: naive_timestamp()
        }
      end)

    Repo.insert_all(Class, new_classes, on_conflict: :nothing)

    school_classes = list_classes(schools_ids: [school_id])

    class_name_class_map =
      class_name_id_map
      |> Enum.map(fn {csv_class_name, class_id} ->
        {
          csv_class_name,
          Enum.find(
            school_classes,
            &(&1.id == class_id or "#{&1.name}" == "#{csv_class_name}")
          )
        }
      end)
      |> Enum.into(%{})

    {:ok, class_name_class_map}
  end

  defp insert_students(%{classes: class_name_class_map} = _changes, csv_students, school_id) do
    students =
      csv_students
      |> Enum.map(
        &{
          &1,
          Enum.into(&1, %{
            school_id: school_id,
            inserted_at: naive_timestamp(),
            updated_at: naive_timestamp(),
            classes:
              case Map.get(class_name_class_map, &1.class_name) do
                nil -> nil
                class -> [class]
              end
          })
        }
      )
      |> Enum.map(&get_or_insert_student/1)

    {:ok, students}
  end

  defp get_or_insert_student({csv_student, %{name: name, school_id: school_id} = student_attrs}) do
    case Repo.get_by(Student, name: name, school_id: school_id) do
      nil ->
        create_student(student_attrs)
        |> case do
          {:ok, student} ->
            create_student_profile(csv_student, student)

          {:error, _changeset} ->
            {csv_student, {:error, "Couldn't create student"}}
        end

      _std ->
        {csv_student, {:error, "Duplicated student"}}
    end
  end

  defp create_student_profile(%{email: ""} = csv_student, student),
    do: {csv_student, {:ok, student}}

  defp create_student_profile(%{email: email} = csv_student, student) do
    with {:ok, user} <- get_or_insert_user(email),
         {:ok, _profile} <-
           Identity.create_profile(%{type: "student", user_id: user.id, student_id: student.id}) do
      {csv_student, {:ok, student}}
    end
  end

  defp get_or_insert_user(email) do
    case Identity.get_user_by_email(email) do
      nil -> Identity.register_user(%{email: email, password: Ecto.UUID.generate()})
      user -> {:ok, user}
    end
  end
end
