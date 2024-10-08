defmodule Lanttern.Schools do
  @moduledoc """
  The Schools context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Student
  alias Lanttern.Schools.Teacher
  alias Lanttern.Identity
  alias Lanttern.Identity.User
  alias Lanttern.Identity.Profile

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
  Returns the list of school cycles.

  ## Options:

      - `:schools_ids` – filter cycles by schools
      - `:order_by` - an order by query expression ([ref](https://hexdocs.pm/ecto/Ecto.Query.html#order_by/3))

  ## Examples

      iex> list_cycles()
      [%Cycle{}, ...]

  """
  def list_cycles(opts \\ []) do
    Cycle
    |> maybe_filter_by_schools(opts)
    |> order_cycles(Keyword.get(opts, :order_by))
    |> Repo.all()
  end

  defp order_cycles(queryable, nil) do
    from c in queryable,
      order_by: [asc: :end_at, desc: :start_at]
  end

  defp order_cycles(queryable, order_by_expression) do
    from c in queryable,
      order_by: ^order_by_expression
  end

  @doc """
  Gets a single cycle.

  Raises `Ecto.NoResultsError` if the Cycle does not exist.

  ## Examples

      iex> get_cycle!(123)
      %Cycle{}

      iex> get_cycle!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cycle!(id), do: Repo.get!(Cycle, id)

  @doc """
  Creates a cycle.

  ## Examples

      iex> create_cycle(%{field: value})
      {:ok, %Cycle{}}

      iex> create_cycle(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cycle(attrs \\ %{}) do
    %Cycle{}
    |> Cycle.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cycle.

  ## Examples

      iex> update_cycle(cycle, %{field: new_value})
      {:ok, %Cycle{}}

      iex> update_cycle(cycle, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cycle(%Cycle{} = cycle, attrs) do
    cycle
    |> Cycle.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cycle.

  ## Examples

      iex> delete_cycle(cycle)
      {:ok, %Cycle{}}

      iex> delete_cycle(cycle)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cycle(%Cycle{} = cycle) do
    Repo.delete(cycle)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cycle changes.

  ## Examples

      iex> change_cycle(cycle)
      %Ecto.Changeset{data: %Cycle{}}

  """
  def change_cycle(%Cycle{} = cycle, attrs \\ %{}) do
    Cycle.changeset(cycle, attrs)
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
    |> maybe_filter_by_schools(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Returns the list of user's school classes.

  The list is sorted by cycle end date (desc), class year (asc), and class name (asc).

  ## Options:

  - `:classes_ids` – filter results by classes
  - `:years_ids` – filter results by years
  - `:preload_cycle_years_students` – boolean

  ## Examples

      iex> list_user_classes()
      [%Class{}, ...]

  """
  def list_user_classes(current_user, opts \\ [])

  def list_user_classes(%{current_profile: %{type: "teacher", school_id: school_id}}, opts) do
    from(
      cl in Class,
      join: cy in assoc(cl, :cycle),
      left_join: y in assoc(cl, :years),
      as: :years,
      group_by: cl.id,
      order_by: [desc: max(cy.end_at), asc: min(y.id), asc: cl.name],
      where: cl.school_id == ^school_id
    )
    |> apply_list_user_classes_opts(opts)
    |> Repo.all()
  end

  def list_user_classes(_current_user, _opts),
    do: {:error, "User not allowed to list classes"}

  defp apply_list_user_classes_opts(queryable, []), do: queryable

  defp apply_list_user_classes_opts(queryable, [{:classes_ids, classes_ids} | opts]) do
    from(cl in queryable, where: cl.id in ^classes_ids)
    |> apply_list_user_classes_opts(opts)
  end

  defp apply_list_user_classes_opts(queryable, [{:years_ids, years_ids} | opts])
       when years_ids != [] do
    from([_cl, years: y] in queryable, where: y.id in ^years_ids)
    |> apply_list_user_classes_opts(opts)
  end

  defp apply_list_user_classes_opts(queryable, [{:preload_cycle_years_students, true} | opts]) do
    from(
      cl in queryable,
      preload: [:cycle, :years, :students]
    )
    |> apply_list_user_classes_opts(opts)
  end

  defp apply_list_user_classes_opts(queryable, [_ | opts]),
    do: apply_list_user_classes_opts(queryable, opts)

  @doc """
  Gets a single class.

  Returns nil if the Class does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_class!(123)
      %Class{}

      iex> get_class!(456)
      nil

  """
  def get_class(id, opts \\ []) do
    Repo.get(Class, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single class.

  Same as `get_class/2`, but raises `Ecto.NoResultsError` if the Class does not exist.
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
    |> Repo.preload([:students, :years])
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

  - `:preloads` – preloads associated data
  - `:school_id` - filter students by school
  - `:students_ids` - filter students by given ids
  - `:classes_ids` – filter students by provided list of ids. preloads the classes for each student, and order by class name
  - `:report_card_id` – filter students linked to given report card. preloads the classes for each student, and order by class name
  - `:check_diff_rubrics_for_strand_id` - used to check if student has any differentiation rubric for given strand id
  - `:base_query` - used in conjunction with `search_students/2`

  ## Examples

      iex> list_students()
      [%Student{}, ...]

  """
  def list_students(opts \\ []) do
    queryable = Keyword.get(opts, :base_query, Student)

    from(s in queryable,
      order_by: s.name
    )
    |> maybe_join_and_preload_classes_in_list_students(opts)
    |> apply_list_students_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_join_and_preload_classes_in_list_students(queryable, opts) do
    case Keyword.keys(opts) |> Enum.any?(&(&1 in [:classes_ids, :report_card_id])) do
      true ->
        from(
          s in Student,
          join: c in assoc(s, :classes),
          as: :classes,
          preload: [classes: c]
        )

      _ ->
        queryable
    end
  end

  defp apply_list_students_opts(queryable, []) do
    from(
      s in queryable,
      order_by: s.name
    )
  end

  defp apply_list_students_opts(queryable, [{:classes_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      [s, classes: c] in queryable,
      where: c.id in ^ids
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      s in queryable,
      where: s.school_id == ^school_id
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:students_ids, students_ids} | opts]) do
    from(
      s in queryable,
      where: s.id in ^students_ids
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:report_card_id, id} | opts]) do
    from(
      [s, classes: c] in queryable,
      join: src in assoc(s, :student_report_cards),
      where: src.report_card_id == ^id
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:check_diff_rubrics_for_strand_id, strand_id} | opts])
       when not is_nil(strand_id) do
    has_diff_query =
      from(
        s in Student,
        left_join: dr in assoc(s, :diff_rubrics),
        left_join: r in assoc(dr, :parent_rubric),
        left_join: ap in Lanttern.Assessments.AssessmentPoint,
        on: ap.rubric_id == r.id and ap.strand_id == ^strand_id,
        group_by: s.id,
        select: %{student_id: s.id, has_diff_rubric: count(ap) > 0}
      )

    from(
      s in queryable,
      join: d in subquery(has_diff_query),
      on: d.student_id == s.id,
      select: %{s | has_diff_rubric: d.has_diff_rubric}
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [_ | opts]),
    do: apply_list_students_opts(queryable, opts)

  @doc """
  Search students by name.

  ## Options:

  View `list_students/1` for `opts`

  ## Examples

      iex> search_students("some name")
      [%Student{}, ...]

  """
  @spec search_students(search_term :: binary(), opts :: Keyword.t()) :: [Student.t()]
  def search_students(search_term, opts \\ []) do
    ilike_search_term = "%#{search_term}%"

    query =
      from(
        s in Student,
        where: ilike(s.name, ^ilike_search_term),
        order_by: {:asc, fragment("? <<-> ?", ^search_term, s.name)}
      )

    [{:base_query, query} | opts]
    |> list_students()
  end

  @doc """
  Gets a single student.

  Returns `nil` if the Student does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_student(123)
      %Student{}

      iex> get_student(456)
      nil

  """
  def get_student(id, opts \\ []) do
    Repo.get(Student, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student.

  Same as `get_student/2`, but raises `Ecto.NoResultsError` if the Student does not exist.
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

      iex> create_students_from_csv(csv_rows, class_name_id_map, school_id)
      [{csv_student, {:ok, %Student{}}}, ...]

  """
  def create_students_from_csv(csv_rows, class_name_id_map, school_id, cycle_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:classes, fn _repo, _changes ->
      insert_csv_classes(class_name_id_map, school_id, cycle_id)
    end)
    |> Ecto.Multi.run(:students, fn _repo, changes ->
      insert_csv_students(changes, csv_rows, school_id)
    end)
    |> Ecto.Multi.run(:users, fn _repo, _changes ->
      insert_csv_users(csv_rows)
    end)
    |> Ecto.Multi.run(:profiles, fn _repo, changes ->
      insert_csv_profiles(changes, csv_rows, "student")
    end)
    |> Ecto.Multi.run(:response, fn _repo, changes ->
      format_response(changes, csv_rows, "student")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes.response}
      error_tuple -> error_tuple
    end
  end

  defp insert_csv_classes(class_name_id_map, school_id, cycle_id) do
    name_class_map =
      class_name_id_map
      |> Enum.map(&get_or_insert_csv_class(&1, school_id, cycle_id))
      |> Enum.into(%{})

    {:ok, name_class_map}
  end

  defp get_or_insert_csv_class({csv_class_name, ""}, school_id, cycle_id) do
    {:ok, class} =
      create_class(%{
        name: csv_class_name,
        school_id: school_id,
        cycle_id: cycle_id
      })

    {csv_class_name, class}
  end

  defp get_or_insert_csv_class({csv_class_name, class_id}, _school_id, _cycle_id),
    do: {csv_class_name, get_class!(class_id)}

  defp insert_csv_students(%{classes: name_class_map} = _changes, csv_rows, school_id) do
    name_student_map =
      csv_rows
      |> Enum.map(&get_or_insert_csv_student(&1, name_class_map, school_id))
      |> Enum.filter(fn
        {:ok, _student} -> true
        {:error, _changeset} -> false
      end)
      |> Enum.map(fn {:ok, student} -> {student.name, student} end)
      |> Enum.into(%{})

    {:ok, name_student_map}
  end

  defp get_or_insert_csv_student(csv_row, name_class_map, school_id) do
    case Repo.get_by(Student, name: csv_row.name, school_id: school_id) do
      nil ->
        %{
          name: csv_row.name,
          school_id: school_id,
          classes:
            case Map.get(name_class_map, csv_row.class_name) do
              nil -> []
              class -> [class]
            end
        }
        |> create_student()

      student ->
        {:ok, student}
    end
  end

  @doc """
  Create teachers, users, and profiles based on CSV data.

  It returns a tuple with the `csv_teacher` as the first item,
  and a nested `:ok` or `:error` tuple, with the created teacher or an error message.

  ### User and profile creation

  If there's no email in the CSV row, user and profile creation is skipped.

  If a user with the email already exists, we create a teacher profile linked to this user.

  Else, we create a user with the teacher email and a linked teacher profile.

  ## Examples

      iex> create_teachers_from_csv(csv_rows, school_id)
      [{csv_teacher, {:ok, %Teacher{}}}, ...]

  """
  def create_teachers_from_csv(csv_rows, school_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:teachers, fn _repo, _changes ->
      insert_csv_teachers(csv_rows, school_id)
    end)
    |> Ecto.Multi.run(:users, fn _repo, _changes ->
      insert_csv_users(csv_rows)
    end)
    |> Ecto.Multi.run(:profiles, fn _repo, changes ->
      insert_csv_profiles(changes, csv_rows, "teacher")
    end)
    |> Ecto.Multi.run(:response, fn _repo, changes ->
      format_response(changes, csv_rows, "teacher")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes.response}
      error_tuple -> error_tuple
    end
  end

  defp insert_csv_teachers(csv_rows, school_id) do
    name_teacher_map =
      csv_rows
      |> Enum.map(&get_or_insert_csv_teacher(&1, school_id))
      |> Enum.filter(fn
        {:ok, _teacher} -> true
        {:error, _changeset} -> false
      end)
      |> Enum.map(fn {:ok, teacher} -> {teacher.name, teacher} end)
      |> Enum.into(%{})

    {:ok, name_teacher_map}
  end

  defp get_or_insert_csv_teacher(csv_row, school_id) do
    case Repo.get_by(Teacher, name: csv_row.name, school_id: school_id) do
      nil ->
        %{
          name: csv_row.name,
          school_id: school_id
        }
        |> create_teacher()

      teacher ->
        {:ok, teacher}
    end
  end

  defp insert_csv_users(csv_rows) do
    email_user_map =
      csv_rows
      |> Enum.filter(&(&1.email != ""))
      |> Enum.map(&get_or_insert_csv_user/1)
      |> Enum.map(&{&1.email, &1})
      |> Enum.into(%{})

    {:ok, email_user_map}
  end

  defp get_or_insert_csv_user(%{email: email}) do
    case Repo.get_by(User, email: email) do
      nil ->
        {:ok, user} =
          %{
            email: email,
            password: Ecto.UUID.generate()
          }
          |> Identity.register_user()

        user

      user ->
        user
    end
  end

  defp insert_csv_profiles(changes, csv_rows, type) do
    name_schema_map =
      case type do
        "student" -> changes.students
        "teacher" -> changes.teachers
      end

    email_user_map = changes.users

    profiles =
      csv_rows
      |> Enum.filter(&(&1.email != "" && &1.name != ""))
      |> Enum.map(
        &%{
          type: type,
          teacher_id:
            if(type == "teacher",
              do: Map.get(name_schema_map, &1.name).id,
              else: nil
            ),
          student_id:
            if(type == "student",
              do: Map.get(name_schema_map, &1.name).id,
              else: nil
            ),
          user_id: Map.get(email_user_map, &1.email).id,
          inserted_at: naive_timestamp(),
          updated_at: naive_timestamp()
        }
      )

    Repo.insert_all(Profile, profiles, on_conflict: :nothing)

    {:ok, true}
  end

  defp format_response(changes, csv_rows, type) do
    name_schema_map =
      case type do
        "student" -> changes.students
        "teacher" -> changes.teachers
      end

    response =
      csv_rows
      |> Enum.map(
        &{
          &1,
          case Map.get(name_schema_map, &1.name) do
            nil -> {:error, "No success"}
            schema -> {:ok, schema}
          end
        }
      )

    {:ok, response}
  end

  # Helpers

  defp maybe_filter_by_schools(query, opts) do
    case Keyword.get(opts, :schools_ids) do
      nil ->
        query

      schools_ids ->
        from(
          q in query,
          where: q.school_id in ^schools_ids
        )
    end
  end
end
