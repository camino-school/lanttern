defmodule Lanttern.Schools do
  @moduledoc """
  The Schools context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Repo

  alias Lanttern.Identity
  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.User
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.ClassStaffMember
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.StaffMember
  alias Lanttern.Schools.Student
  alias Lanttern.SupabaseHelpers

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
  - `:order` - `:desc` (default) or `:asc`
  - `:parent_cycles_only` – list only cycles without `parent_cycle_id` when `true`
  - `:subcycles_only` – list only cycles with `parent_cycle_id` when `true`
  - `:subcycles_of_parent_id` – list only subcycles of given parent cycle
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_cycles()
      [%Cycle{}, ...]

  """
  def list_cycles(opts \\ []) do
    Cycle
    |> apply_list_cycles_opts(opts)
    |> apply_list_cycles_order(Keyword.get(opts, :order))
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_cycles_opts(queryable, []), do: queryable

  defp apply_list_cycles_opts(queryable, [{:schools_ids, schools_ids} | opts]) do
    from(
      c in queryable,
      where: c.school_id in ^schools_ids
    )
    |> apply_list_cycles_opts(opts)
  end

  defp apply_list_cycles_opts(queryable, [{:parent_cycles_only, true} | opts]) do
    from(
      c in queryable,
      where: is_nil(c.parent_cycle_id)
    )
    |> apply_list_cycles_opts(opts)
  end

  defp apply_list_cycles_opts(queryable, [{:subcycles_only, true} | opts]) do
    from(
      c in queryable,
      where: not is_nil(c.parent_cycle_id)
    )
    |> apply_list_cycles_opts(opts)
  end

  defp apply_list_cycles_opts(queryable, [{:subcycles_of_parent_id, parent_id} | opts])
       when is_integer(parent_id) do
    from(
      c in queryable,
      where: c.parent_cycle_id == ^parent_id
    )
    |> apply_list_cycles_opts(opts)
  end

  defp apply_list_cycles_opts(queryable, [_ | opts]),
    do: apply_list_cycles_opts(queryable, opts)

  defp apply_list_cycles_order(queryable, :asc) do
    from c in queryable,
      order_by: [asc: :start_at, asc: :end_at]
  end

  defp apply_list_cycles_order(queryable, _) do
    from c in queryable,
      order_by: [desc: :end_at, asc: :start_at]
  end

  @doc """
  Returns the list of school cycles with preloaded subcycles.

  ## Options:

  - `:schools_ids` – filter cycles by schools
  - `:order` - `:desc` (defautl) or `:asc`

  ## Examples

      iex> list_cycles_and_subcycles()
      [%Cycle{}, ...]

  """
  def list_cycles_and_subcycles(opts \\ []) do
    order =
      Keyword.get(opts, :order)
      |> set_list_cycles_and_subcycles_order()

    from(
      c in Cycle,
      left_join: sc in assoc(c, :subcycles),
      where: is_nil(c.parent_cycle_id),
      preload: [subcycles: sc],
      order_by: ^order
    )
    |> apply_list_cycles_and_subcycles_opts(opts)
    |> Repo.all()
  end

  defp set_list_cycles_and_subcycles_order(:asc),
    do: [
      asc: :start_at,
      asc: :end_at,
      asc: dynamic([_c, sc], sc.start_at),
      asc: dynamic([_c, sc], sc.end_at)
    ]

  defp set_list_cycles_and_subcycles_order(_),
    do: [
      desc: :end_at,
      asc: :start_at,
      desc: dynamic([_c, sc], sc.end_at),
      asc: dynamic([_c, sc], sc.start_at)
    ]

  defp apply_list_cycles_and_subcycles_opts(queryable, []), do: queryable

  defp apply_list_cycles_and_subcycles_opts(queryable, [{:schools_ids, schools_ids} | opts]) do
    from(
      c in queryable,
      where: c.school_id in ^schools_ids
    )
    |> apply_list_cycles_and_subcycles_opts(opts)
  end

  defp apply_list_cycles_and_subcycles_opts(queryable, [_ | opts]),
    do: apply_list_cycles_and_subcycles_opts(queryable, opts)

  @doc """
  Gets a single cycle.

  Returns `nil` if the Cycle does not exist.

  ## Options:

  - `:preloads` – preloads associated data
  - `:check_permissions_for_user` - expects a `%User{}` (usually from `socket.assigns.current_user`), and will check for class access based on school and permissions

  ## Examples

      iex> get_cycle(123)
      %Cycle{}

      iex> get_cycle(456)
      ** (Ecto.NoResultsError)

  """
  def get_cycle(id, opts \\ []) do
    cycle =
      Cycle
      |> Repo.get(id)
      |> maybe_preload(opts)

    case Keyword.get(opts, :check_permissions_for_user) do
      %User{} = user -> apply_get_cycle_check_permissions_for_user(cycle, user)
      _ -> cycle
    end
  end

  defp apply_get_cycle_check_permissions_for_user(
         %Cycle{} = cycle,
         %User{current_profile: %Profile{school_id: school_id} = profile}
       )
       when cycle.school_id == school_id do
    if "school_management" in profile.permissions, do: cycle
  end

  defp apply_get_cycle_check_permissions_for_user(_, _), do: nil

  @doc """
  Gets a single cycle.

  Same as `get_cycle/2`, but raises `Ecto.NoResultsError` if the Cycle does not exist.

  """
  def get_cycle!(id, opts \\ []) do
    Cycle
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets the newest parent cycle from the given school.

  Returns `nil` if there's no parent in the school.

  """
  def get_newest_parent_cycle_from_school(school_id) do
    from(
      c in Cycle,
      where: c.school_id == ^school_id,
      where: is_nil(c.parent_cycle_id),
      order_by: [desc: :end_at, asc: :start_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a cycle.

  ## Options

  - `:preloads` – preloads associated data on return

  ## Examples

      iex> create_cycle(%{field: value})
      {:ok, %Cycle{}}

      iex> create_cycle(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cycle(attrs \\ %{}, opts \\ []) do
    %Cycle{}
    |> Cycle.changeset(attrs)
    |> validate_cycle_parent_cycle_id()
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  defp validate_cycle_parent_cycle_id(%{changes: %{parent_cycle_id: nil}} = changeset),
    do: changeset

  defp validate_cycle_parent_cycle_id(%{changes: %{parent_cycle_id: parent_cycle_id}} = changeset) do
    case Repo.get(Cycle, parent_cycle_id) do
      %Cycle{parent_cycle_id: nil} ->
        changeset

      %Cycle{parent_cycle_id: _} ->
        Ecto.Changeset.add_error(
          changeset,
          :parent_cycle_id,
          gettext("You can't use a subcycle as a parent cycle")
        )

      nil ->
        Ecto.Changeset.add_error(
          changeset,
          :parent_cycle_id,
          gettext("Parent cycle does not exist")
        )
    end
  end

  defp validate_cycle_parent_cycle_id(changeset), do: changeset

  @doc """
  Updates a cycle.

  ## Options

  - `:preloads` – preloads associated data on return

  ## Examples

      iex> update_cycle(cycle, %{field: new_value})
      {:ok, %Cycle{}}

      iex> update_cycle(cycle, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cycle(%Cycle{} = cycle, attrs, opts \\ []) do
    cycle
    |> Cycle.changeset(attrs)
    |> validate_cycle_parent_cycle_id()
    |> Repo.update()
    |> maybe_preload(opts)
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

  Cycle and years are always preloaded.

  ## Options:

  - `:classes_ids` – filter results by given ids
  - `:schools_ids` – filter classes by schools
  - `:years_ids` – filter results by years
  - `:cycles_ids` – filter results by cycles
  - `:count_active_students` - boolean, will add the `active_students_count` field
  - `:preloads` – preloads associated data
  - `:base_query` - used in conjunction with `search_classes/2`

  ## Examples

      iex> list_classes()
      [%Class{}, ...]

  """
  def list_classes(opts \\ []) do
    queryable = Keyword.get(opts, :base_query, Class)

    from(
      cl in queryable,
      join: cy in assoc(cl, :cycle),
      left_join: y in assoc(cl, :years),
      as: :years,
      group_by: [cl.id, cy.id, y.id],
      order_by: [desc: max(cy.end_at), asc: min(y.id), asc: cl.name],
      preload: [cycle: cy, years: y]
    )
    |> apply_list_classes_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_classes_opts(queryable, []), do: queryable

  defp apply_list_classes_opts(queryable, [{:schools_ids, schools_ids} | opts])
       when is_list(schools_ids) and schools_ids != [] do
    from(
      cl in queryable,
      where: cl.school_id in ^schools_ids
    )
    |> apply_list_classes_opts(opts)
  end

  defp apply_list_classes_opts(queryable, [{:classes_ids, classes_ids} | opts])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      cl in queryable,
      where: cl.id in ^classes_ids
    )
    |> apply_list_classes_opts(opts)
  end

  defp apply_list_classes_opts(queryable, [{:years_ids, years_ids} | opts])
       when is_list(years_ids) and years_ids != [] do
    from([_cl, years: y] in queryable, where: y.id in ^years_ids)
    |> apply_list_classes_opts(opts)
  end

  defp apply_list_classes_opts(queryable, [{:cycles_ids, cycles_ids} | opts])
       when is_list(cycles_ids) and cycles_ids != [] do
    from(cl in queryable, where: cl.cycle_id in ^cycles_ids)
    |> apply_list_classes_opts(opts)
  end

  defp apply_list_classes_opts(queryable, [{:count_active_students, true} | opts]) do
    from(
      cl in queryable,
      left_join: s in assoc(cl, :students),
      on: is_nil(s.deactivated_at),
      select_merge: %{active_students_count: count(s)}
    )
    |> apply_list_classes_opts(opts)
  end

  defp apply_list_classes_opts(queryable, [_ | opts]),
    do: apply_list_classes_opts(queryable, opts)

  @doc """
  Returns a list of classes linked to students in the giving date,
  using the relationship between class and cycle.

  `cycle` is preloaded in the results.

  ## Examples

      iex> list_classes_for_students_in_date(students_ids, ~D[2024-08-01])
      [%Class{}, ...]

  """
  @spec list_classes_for_students_in_date(students_ids :: [pos_integer()], Date.t()) :: [
          Class.t()
        ]
  def list_classes_for_students_in_date(students_ids, date) do
    from(
      c in Class,
      join: s in assoc(c, :students),
      on: s.id in ^students_ids,
      join: cy in assoc(c, :cycle),
      where: cy.start_at <= ^date and cy.end_at >= ^date,
      preload: [cycle: cy],
      distinct: true
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of user's school classes.

  It uses `list_classes/1` internally, extracting the `school_id` from
  `current_user.current_profile`.

  View `list_classes/1` for supported opts.

  """
  def list_user_classes(current_user, opts \\ [])

  def list_user_classes(%User{current_profile: %{type: "staff", school_id: school_id}}, opts) do
    opts = Keyword.put(opts, :schools_ids, [school_id])
    list_classes(opts)
  end

  def list_user_classes(_current_user, _opts),
    do: {:error, "User not allowed to list classes"}

  @doc """
  Search classes by name.

  ## Options:

  View `list_classes/1` for `opts`

  ## Examples

      iex> search_classes("some name")
      [%Class{}, ...]

  """
  @spec search_classes(search_term :: binary(), opts :: Keyword.t()) :: [Class.t()]
  def search_classes(search_term, opts \\ []) do
    ilike_search_term = "%#{search_term}%"

    query =
      from(
        c in Class,
        where: ilike(c.name, ^ilike_search_term),
        order_by: {:asc, fragment("? <<-> ?", ^search_term, c.name)}
      )

    [{:base_query, query} | opts]
    |> list_classes()
  end

  @doc """
  Gets a single class.

  Returns nil if the Class does not exist.

  ### Options:

  - `:preloads` – preloads associated data
  - `:check_permissions_for_user` - expects a `%User{}` (usually from `socket.assigns.current_user`), and will check for class access based on school and permissions

  ## Examples

      iex> get_class!(123)
      %Class{}

      iex> get_class!(456)
      nil

  """
  def get_class(id, opts \\ []) do
    class =
      Repo.get(Class, id)
      |> maybe_preload(opts)

    case Keyword.get(opts, :check_permissions_for_user) do
      %User{} = user -> apply_get_class_check_permissions_for_user(class, user)
      _ -> class
    end
  end

  defp apply_get_class_check_permissions_for_user(
         %Class{} = class,
         %User{current_profile: %Profile{school_id: school_id} = profile}
       )
       when class.school_id == school_id do
    if "school_management" in profile.permissions, do: class
  end

  defp apply_get_class_check_permissions_for_user(_, _), do: nil

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
  def create_class(attrs \\ %{}, current_user) do
    %Class{}
    |> Class.changeset(attrs, current_user.current_profile)
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
  def update_class(%Class{} = class, attrs, current_user) do
    class
    |> Repo.preload([:students, :years, :staff_members])
    |> Class.changeset(attrs, current_user.current_profile)
    |> Repo.update()
  end

  @doc """
  Deletes a class and related years/students relationships.

  ## Examples

      iex> delete_class(class)
      {:ok, %Class{}}

      iex> delete_class(class)
      {:error, %Ecto.Changeset{}}

  """
  def delete_class(%Class{} = class) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(
      :delete_class_years,
      from(
        cy in "classes_years",
        where: cy.class_id == ^class.id
      )
    )
    |> Ecto.Multi.delete_all(
      :delete_class_students,
      from(
        cs in "classes_students",
        where: cs.class_id == ^class.id
      )
    )
    |> Ecto.Multi.delete(:delete_class, class)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_class: %Class{} = class}} -> {:ok, class}
      res -> res
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking class changes.

  ## Examples

      iex> change_class(class)
      %Ecto.Changeset{data: %Class{}}

  """
  def change_class(%Class{} = class, current_user) do
    Class.changeset(class, %{}, current_user.current_profile)
  end

  def change_class(%Class{} = class, attrs, current_user) do
    Class.changeset(class, attrs, current_user.current_profile)
  end

  @doc """
  Returns the list of students.

  ### Options:

  - `:preloads` – preloads associated data
  - `:school_id` - filter students by school
  - `:students_ids` - filter students by given ids
  - `:student_tags_ids` - filter students by their associated tags
  - `:class_id` – filter students by given class
  - `:classes_ids` – filter students by provided list of ids. preloads the classes for each student, and order by class name
  - `:only_in_some_class` - boolean. When `true`, will remove students not linked to a class (and will do the opposite when `false`)
  - `:load_email` - boolean, will add the email field based on staff member profile/user
  - `:only_active` - boolean, will return only active students
  - `:only_deactivated` - boolean, will return only deactivated students
  - `:preload_classes_from_cycle_id` - preload classes, filtered by cycle id
  - `:load_profile_picture_from_cycle_id` - will try to load the profile picture from linked `%StudentCycleInfo{}` with the given cycle id
  - `:base_query` - used in conjunction with `search_students/2`

  ## Examples

      iex> list_students()
      [%Student{}, ...]

  """
  def list_students(opts \\ []) do
    queryable = Keyword.get(opts, :base_query, Student)

    from(
      s in queryable,
      order_by: s.name
    )
    |> apply_list_students_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_students_opts(queryable, []), do: queryable

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

  defp apply_list_students_opts(queryable, [{:student_tags_ids, student_tags_ids} | opts])
       when is_list(student_tags_ids) and student_tags_ids != [] do
    from(
      s in queryable,
      join: str in Lanttern.StudentTags.StudentTagRelationship,
      on: str.student_id == s.id,
      where: str.tag_id in ^student_tags_ids,
      # use preload to prevent duplicated students
      preload: [student_tag_relationships: str]
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:class_id, id} | opts]) do
    from(
      [s, classes: c] in bind_classes_to_students(queryable),
      where: c.id == ^id
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:classes_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      [s, classes: c] in bind_classes_to_students(queryable),
      where: c.id in ^ids
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:only_in_some_class, true} | opts]) do
    from(
      [s, classes: c] in bind_classes_to_students(queryable),
      where: not is_nil(c)
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:only_in_some_class, false} | opts]) do
    from(
      [s, classes: c] in bind_classes_to_students(queryable),
      where: is_nil(c)
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:load_email, true} | opts]) do
    from(s in queryable,
      left_join: p in assoc(s, :profile),
      left_join: u in assoc(p, :user),
      select_merge: %{email: u.email}
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:only_active, true} | opts]) do
    from(s in queryable, where: is_nil(s.deactivated_at))
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:only_deactivated, true} | opts]) do
    from(s in queryable, where: not is_nil(s.deactivated_at))
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [{:preload_classes_from_cycle_id, cycle_id} | opts]) do
    cycle_classes_query = from c in Class, where: c.cycle_id == ^cycle_id

    from(
      s in queryable,
      preload: [classes: ^cycle_classes_query]
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [
         {:load_profile_picture_from_cycle_id, cycle_id} | opts
       ]) do
    from(
      s in queryable,
      left_join: sci in assoc(s, :cycles_info),
      on: sci.cycle_id == ^cycle_id,
      select_merge: %{profile_picture_url: sci.profile_picture_url}
    )
    |> apply_list_students_opts(opts)
  end

  defp apply_list_students_opts(queryable, [_ | opts]),
    do: apply_list_students_opts(queryable, opts)

  defp bind_classes_to_students(queryable) do
    with_named_binding(queryable, :classes, fn queryable, binding ->
      join(queryable, :left, [s], c in assoc(s, ^binding), as: ^binding)
    end)
  end

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

  - `:load_email` - boolean, will add the email field based on staff member profile/user
  - `:load_profile_picture_from_cycle_id` - will try to load the profile picture from linked `%StudentCycleInfo{}` with the given cycle id
  - `:preload_classes_from_cycle_id` - preload classes linked to student on given cycle id
  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student(123)
      %Student{}

      iex> get_student(456)
      nil

  """
  def get_student(id, opts \\ []) do
    Student
    |> apply_get_student_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_get_student_opts(queryable, []), do: queryable

  defp apply_get_student_opts(queryable, [{:load_email, true} | opts]) do
    from(s in queryable,
      left_join: p in assoc(s, :profile),
      left_join: u in assoc(p, :user),
      select_merge: %{email: u.email}
    )
    |> apply_get_student_opts(opts)
  end

  defp apply_get_student_opts(queryable, [
         {:load_profile_picture_from_cycle_id, cycle_id} | opts
       ]) do
    from(
      s in queryable,
      left_join: sci in assoc(s, :cycles_info),
      on: sci.cycle_id == ^cycle_id,
      select_merge: %{profile_picture_url: sci.profile_picture_url}
    )
    |> apply_get_student_opts(opts)
  end

  defp apply_get_student_opts(queryable, [
         {:preload_classes_from_cycle_id, cycle_id} | opts
       ]) do
    from(
      s in queryable,
      left_join: c in assoc(s, :classes),
      on: c.cycle_id == ^cycle_id,
      order_by: c.name,
      preload: [classes: c]
    )
    |> apply_get_student_opts(opts)
  end

  defp apply_get_student_opts(queryable, [_ | opts]),
    do: apply_get_student_opts(queryable, opts)

  @doc """
  Gets a single student.

  Same as `get_student/2`, but raises `Ecto.NoResultsError` if the Student does not exist.
  """
  def get_student!(id, opts \\ []) do
    Student
    |> apply_get_student_opts(opts)
    |> Repo.get!(id)
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
    email = Map.get(attrs, "email") || Map.get(attrs, :email)

    if is_binary(email) && email != "" do
      create_with_profile(%Student{}, attrs, email)
    else
      %Student{}
      |> Student.changeset(attrs)
      |> Repo.insert()
    end
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
    has_email_in_attrs = Map.keys(attrs) |> Enum.any?(&(&1 in ["email", :email]))

    email =
      case Map.get(attrs, "email") || Map.get(attrs, :email) do
        nil -> nil
        "" -> nil
        email -> email
      end

    if has_email_in_attrs and student.email != email do
      update_with_profile(student, attrs, email)
    else
      student
      |> Student.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Deletes a student and related classes relationships.

  ## Examples

      iex> delete_student(student)
      {:ok, %Student{}}

      iex> delete_student(student)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student(%Student{} = student) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(
      :delete_classes_students,
      from(
        cs in "classes_students",
        where: cs.student_id == ^student.id
      )
    )
    |> Ecto.Multi.delete(:delete_student, student)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_student: %Student{} = student}} -> {:ok, student}
      res -> res
    end
  end

  @doc """
  Deactivates a studdent.

  Soft delete, using the `deactivated_at` field.

  ## Examples

      iex> deactivate_student(student)
      {:ok, %Student{}}

      iex> deactivate_student(student)
      {:error, %Ecto.Changeset{}}

  """
  @spec deactivate_student(Student.t()) ::
          {:ok, Student.t()} | {:error, Ecto.Changeset.t()}
  def deactivate_student(%Student{} = student) do
    student
    |> Student.changeset(%{deactivated_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Reactivates a studdent.

  Sets `deactivated_at` field to nil.

  ## Examples

  iex> reactivate_student(student)
  {:ok, %Student{}}

  iex> reactivate_student(student)
  {:error, %Ecto.Changeset{}}

  """
  @spec reactivate_student(Student.t()) ::
          {:ok, Student.t()} | {:error, Ecto.Changeset.t()}
  def reactivate_student(%Student{} = student) do
    student
    |> Student.changeset(%{deactivated_at: nil})
    |> Repo.update()
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
  Returns the list of staff members.

  ### Options:

  - `:school_id` – filter staff members by school
  - `:staff_members_ids` – filter staff members by provided ids
  - `:load_email` - boolean, will add the email field based on staff member profile/user
  - `:only_active` - boolean, will return only active staff members
  - `:only_deactivated` - boolean, will return only deactivated staff members
  - `:preloads` – preloads associated data
  - `:base_query` - used in conjunction with `search_staff_members/2`

  ## Examples

      iex> list_staff_members()
      [%StaffMember{}, ...]

  """
  def list_staff_members(opts \\ []) do
    queryable = Keyword.get(opts, :base_query, StaffMember)

    from(
      sm in queryable,
      order_by: sm.name
    )
    |> apply_list_staff_members_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_staff_members_opts(queryable, []), do: queryable

  defp apply_list_staff_members_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      sm in queryable,
      where: sm.school_id == ^school_id
    )
    |> apply_list_staff_members_opts(opts)
  end

  defp apply_list_staff_members_opts(queryable, [{:staff_members_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      sm in queryable,
      where: sm.id in ^ids
    )
    |> apply_list_staff_members_opts(opts)
  end

  defp apply_list_staff_members_opts(queryable, [{:load_email, true} | opts]) do
    from(sm in queryable,
      left_join: p in assoc(sm, :profile),
      left_join: u in assoc(p, :user),
      select: %{sm | email: u.email}
    )
    |> apply_list_staff_members_opts(opts)
  end

  defp apply_list_staff_members_opts(queryable, [{:only_active, true} | opts]) do
    from(sm in queryable, where: is_nil(sm.deactivated_at))
    |> apply_list_staff_members_opts(opts)
  end

  defp apply_list_staff_members_opts(queryable, [{:only_deactivated, true} | opts]) do
    from(sm in queryable, where: not is_nil(sm.deactivated_at))
    |> apply_list_staff_members_opts(opts)
  end

  defp apply_list_staff_members_opts(queryable, [_ | opts]),
    do: apply_list_staff_members_opts(queryable, opts)

  @doc """
  Search staff members by name.

  ## Options:

  View `list_staff_members/1` for `opts`

  ## Examples

      iex> search_staff_members("some name")
      [%StaffMember{}, ...]

  """
  @spec search_staff_members(search_term :: binary(), opts :: Keyword.t()) :: [StaffMember.t()]
  def search_staff_members(search_term, opts \\ []) do
    ilike_search_term = "%#{search_term}%"

    query =
      from(
        sm in StaffMember,
        where: ilike(sm.name, ^ilike_search_term),
        order_by: {:asc, fragment("? <<-> ?", ^search_term, sm.name)}
      )

    [{:base_query, query} | opts]
    |> list_staff_members()
  end

  @doc """
  Gets a single staff member.

  Raises `Ecto.NoResultsError` if the StaffMember does not exist.

  ### Options:

  - `:load_email` - boolean, will add the email field based on staff member profile/user
  - `:preloads` – preloads associated data

  ## Examples

      iex> get_staff_member!(123)
      %StaffMember{}

      iex> get_staff_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_staff_member!(id, opts \\ []) do
    StaffMember
    |> apply_get_staff_member_opts(opts)
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  defp apply_get_staff_member_opts(queryable, []), do: queryable

  defp apply_get_staff_member_opts(queryable, [{:load_email, true} | opts]) do
    from(sm in queryable,
      left_join: p in assoc(sm, :profile),
      left_join: u in assoc(p, :user),
      select: %{sm | email: u.email}
    )
    |> apply_get_staff_member_opts(opts)
  end

  defp apply_get_staff_member_opts(queryable, [_ | opts]),
    do: apply_get_staff_member_opts(queryable, opts)

  @doc """
  Creates a staff member.

  If attr contains an email, it will create (or link) a user and profile for the staff member.

  ## Examples

      iex> create_staff_member(%{field: value})
      {:ok, %StaffMember{}}

      iex> create_staff_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_staff_member(attrs \\ %{}) do
    email = Map.get(attrs, "email") || Map.get(attrs, :email)

    if is_binary(email) && email != "" do
      create_with_profile(%StaffMember{}, attrs, email)
    else
      %StaffMember{}
      |> StaffMember.changeset(attrs)
      |> Repo.insert()
    end
  end

  defp create_with_profile(schema, attrs, email) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :school_person,
      school_person_changeset(schema, attrs)
    )
    |> Ecto.Multi.run(
      :user,
      fn _repo, _changes ->
        get_or_create_user_with_email(email)
      end
    )
    |> Ecto.Multi.run(
      :profile,
      fn _repo, changes -> create_profile(changes) end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{school_person: school_person}} -> {:ok, %{school_person | email: email}}
      {:error, _name, value, _changes_so_far} -> {:error, value}
    end
  end

  defp school_person_changeset(%StaffMember{} = staff_member, attrs),
    do: StaffMember.changeset(staff_member, attrs)

  defp school_person_changeset(%Student{} = student, attrs),
    do: Student.changeset(student, attrs)

  defp get_or_create_user_with_email(nil), do: {:ok, nil}

  defp get_or_create_user_with_email(""), do: {:ok, nil}

  defp get_or_create_user_with_email(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        %{
          email: email,
          password: Ecto.UUID.generate()
        }
        |> Identity.register_user()

      user ->
        {:ok, user}
    end
  end

  defp create_profile(%{school_person: school_person, user: user}) do
    profile_attrs =
      case school_person do
        %StaffMember{} ->
          %{
            type: "staff",
            user_id: user.id,
            staff_member_id: school_person.id
          }

        %Student{} ->
          %{
            type: "student",
            user_id: user.id,
            student_id: school_person.id
          }
      end

    Identity.create_profile(profile_attrs)
  end

  @doc """
  Updates a staff member.

  If attr contains an email, it will handle the profile creation,
  update, or deletion based on the email change. Requires the staff
  member to have loaded the email field.

  ## Examples

      iex> update_staff_member(staff_member, %{field: new_value})
      {:ok, %StaffMember{}}

      iex> update_staff_member(staff_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_staff_member(%StaffMember{} = staff_member, attrs) do
    has_email_in_attrs = Map.keys(attrs) |> Enum.any?(&(&1 in ["email", :email]))

    email =
      case Map.get(attrs, "email") || Map.get(attrs, :email) do
        nil -> nil
        "" -> nil
        email -> email
      end

    if has_email_in_attrs and staff_member.email != email do
      update_with_profile(staff_member, attrs, email)
    else
      staff_member
      |> StaffMember.changeset(attrs)
      |> Repo.update()
      |> update_staff_member_cleanup(staff_member)
    end
  end

  defp update_with_profile(school_person, attrs, email) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :school_person,
      school_person_changeset(school_person, attrs)
    )
    |> Ecto.Multi.run(
      :user,
      fn _repo, _changes ->
        get_or_create_user_with_email(email)
      end
    )
    |> Ecto.Multi.run(
      :profile,
      fn _repo, changes ->
        create_update_or_delete_profile(changes)
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{school_person: school_person}} -> {:ok, %{school_person | email: email}}
      {:error, _name, value, _changes_so_far} -> {:error, value}
    end
    |> update_staff_member_cleanup(school_person)
  end

  defp create_update_or_delete_profile(%{school_person: school_person, user: nil}) do
    get_by_opt =
      case school_person do
        %StaffMember{} -> [staff_member_id: school_person.id]
        %Student{} -> [student_id: school_person.id]
      end

    Repo.get_by(Profile, get_by_opt)
    |> Repo.delete()
  end

  defp create_update_or_delete_profile(%{
         school_person: %{email: nil} = school_person,
         user: %User{} = user
       }) do
    profile_attrs =
      case school_person do
        %StaffMember{} ->
          %{
            type: "staff",
            user_id: user.id,
            staff_member_id: school_person.id
          }

        %Student{} ->
          %{
            type: "student",
            user_id: user.id,
            student_id: school_person.id
          }
      end

    Identity.create_profile(profile_attrs)
  end

  defp create_update_or_delete_profile(%{school_person: school_person, user: %User{} = user}) do
    get_by_opt =
      case school_person do
        %StaffMember{} -> [staff_member_id: school_person.id]
        %Student{} -> [student_id: school_person.id]
      end

    Repo.get_by(Profile, get_by_opt)
    |> Identity.update_profile(%{user_id: user.id})
  end

  defp update_staff_member_cleanup(
         {:ok, %StaffMember{profile_picture_url: updated_profile_picture_url}} = return_tuple,
         %StaffMember{profile_picture_url: old_profile_picture_url}
       )
       when updated_profile_picture_url != old_profile_picture_url and
              is_binary(old_profile_picture_url) do
    # when updating a staff member, we also want to remove the old profile picture from the cloud if needed
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      SupabaseHelpers.remove_object("profile_pictures", old_profile_picture_url)
    end)

    return_tuple
  end

  defp update_staff_member_cleanup(return_tuple, _old_staff_member),
    do: return_tuple

  @doc """
  Deletes a staff member.

  ## Examples

      iex> delete_staff_member(staff_member)
      {:ok, %StaffMember{}}

      iex> delete_staff_member(staff_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_staff_member(%StaffMember{} = staff_member) do
    Repo.delete(staff_member)
    |> delete_staff_member_cleanup()
  end

  defp delete_staff_member_cleanup(
         {:ok, %StaffMember{profile_picture_url: profile_picture_url}} = return_tuple
       )
       when is_binary(profile_picture_url) do
    # when deleting a staff member, we also want to remove their profile picture from the cloud if needed
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      SupabaseHelpers.remove_object("profile_pictures", profile_picture_url)
    end)

    return_tuple
  end

  defp delete_staff_member_cleanup(return_tuple), do: return_tuple

  @doc """
  Deactivates a staff member.

  Soft delete, using the `deactivated_at` field.

  ## Examples

      iex> deactivate_staff_member(staff_member)
      {:ok, %StaffMember{}}

      iex> deactivate_staff_member(staff_member)
      {:error, %Ecto.Changeset{}}

  """
  @spec deactivate_staff_member(StaffMember.t()) ::
          {:ok, StaffMember.t()} | {:error, Ecto.Changeset.t()}
  def deactivate_staff_member(%StaffMember{} = staff_member) do
    staff_member
    |> StaffMember.changeset(%{deactivated_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Reactivates a staff member.

  Sets `deactivated_at` field to nil.

  ## Examples

      iex> reactivate_staff_member(staff_member)
      {:ok, %StaffMember{}}

      iex> reactivate_staff_member(staff_member)
      {:error, %Ecto.Changeset{}}

  """
  @spec reactivate_staff_member(StaffMember.t()) ::
          {:ok, StaffMember.t()} | {:error, Ecto.Changeset.t()}
  def reactivate_staff_member(%StaffMember{} = staff_member) do
    staff_member
    |> StaffMember.changeset(%{deactivated_at: nil})
    |> Repo.update()
  end

  @doc """
  Returns the list of staff members for a class, ordered by position.

  ### Options:

  - `:preloads` – preloads associated data
  - `:load_email` - boolean, will add the email field based on staff member profile/user

  ## Examples

      iex> list_class_staff_members(scope, class_id)
      [%StaffMember{}, ...]

  """
  def list_class_staff_members(scope, class_id, opts \\ []) do
    load_email? = Keyword.get(opts, :load_email, false)

    base_query =
      from(csm in ClassStaffMember,
        join: sm in assoc(csm, :staff_member),
        join: cl in assoc(csm, :class),
        where: csm.class_id == ^class_id,
        where: cl.school_id == ^scope.school_id,
        where: is_nil(sm.deactivated_at),
        order_by: [asc: csm.position],
        select: %{
          sm
          | class_role: csm.role,
            class_staff_member_id: csm.id,
            position: csm.position
        }
      )

    query =
      if load_email? do
        from([csm, sm] in base_query,
          left_join: p in assoc(sm, :profile),
          left_join: u in assoc(p, :user),
          select_merge: %{email: u.email}
        )
      else
        base_query
      end

    result =
      query
      |> Repo.all()

    result
    |> maybe_preload(opts)
  end

  @doc """
  Returns the list of classes for a staff member, ordered by position.

  ## Examples

      iex> list_staff_member_classes(staff_member_id)
      [%ClassStaffMember{}, ...]

  """
  def list_staff_member_classes(staff_member_id, _opts \\ []) do
    from(csm in ClassStaffMember,
      join: c in assoc(csm, :class),
      where: csm.staff_member_id == ^staff_member_id,
      order_by: [asc: csm.position],
      preload: [class: {c, [:school, :cycle]}]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single class staff member relationship.

  Raises `Ecto.NoResultsError` if not found.

  ## Examples

      iex> get_class_staff_member!(id)
      %ClassStaffMember{}

  """
  def get_class_staff_member!(id, opts \\ []) do
    ClassStaffMember
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Adds a staff member to a class.

  Position is auto-assigned using RepoHelpers.set_position_in_attrs/2.

  ## Examples

      iex> add_staff_member_to_class(%{class_id: 1, staff_member_id: 2})
      {:ok, %ClassStaffMember{}}

      iex> add_staff_member_to_class(%{class_id: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_staff_member_to_class(attrs) do
    class_id = Map.get(attrs, :class_id) || Map.get(attrs, "class_id")

    position_queryable =
      from(csm in ClassStaffMember,
        where: csm.class_id == ^class_id
      )

    set_position_in_attrs(position_queryable, attrs)
    |> then(&ClassStaffMember.changeset(%ClassStaffMember{}, &1))
    |> Repo.insert()
  end

  @doc """
  Updates a class staff member relationship (role and/or position).

  ## Examples

      iex> update_class_staff_member(class_staff_member, %{role: "Lead Teacher"})
      {:ok, %ClassStaffMember{}}

      iex> update_class_staff_member(class_staff_member, %{role: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_class_staff_member(%ClassStaffMember{} = class_staff_member, attrs) do
    class_staff_member
    |> ClassStaffMember.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes a staff member from a class.

  ## Examples

      iex> remove_staff_member_from_class(class_staff_member)
      {:ok, %ClassStaffMember{}}

      iex> remove_staff_member_from_class(class_staff_member)
      {:error, %Ecto.Changeset{}}

  """
  def remove_staff_member_from_class(%ClassStaffMember{} = class_staff_member) do
    Repo.delete(class_staff_member)
  end

  @doc """
  Updates class staff members positions based on ids list order.

  ## Examples

      iex> update_class_staff_members_positions(class_id, [3, 2, 1])
      :ok

  """
  def update_class_staff_members_positions(class_id, ids_list) do
    queryable = from(csm in ClassStaffMember, where: csm.class_id == ^class_id)
    update_positions(queryable, ids_list, id_field: :staff_member_id)
  end

  @doc """
  Updates staff member classes positions based on ids list order.

  ## Examples

      iex> update_staff_member_classes_positions(staff_member_id, [3, 2, 1])
      :ok

  """
  def update_staff_member_classes_positions(staff_member_id, ids_list) do
    queryable = from(csm in ClassStaffMember, where: csm.staff_member_id == ^staff_member_id)
    update_positions(queryable, ids_list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking staff member changes.

  ## Examples

      iex> change_staff_member(staff_member)
      %Ecto.Changeset{data: %StaffMember{}}

  """
  def change_staff_member(%StaffMember{} = staff_member, attrs \\ %{}) do
    StaffMember.changeset(staff_member, attrs)
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
  Create staff_members, users, and profiles based on CSV data.

  It returns a tuple with the `csv_staff_member` as the first item,
  and a nested `:ok` or `:error` tuple, with the created staff member or an error message.

  ### User and profile creation

  If there's no email in the CSV row, user and profile creation is skipped.

  If a user with the email already exists, we create a staff member profile linked to this user.

  Else, we create a user with the staff member email and a linked staff member profile.

  ## Examples

      iex> create_staff_members_from_csv(csv_rows, school_id)
      [{csv_staff_member, {:ok, %StaffMember{}}}, ...]

  """
  def create_staff_members_from_csv(csv_rows, school_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:staff_members, fn _repo, _changes ->
      insert_csv_staff_members(csv_rows, school_id)
    end)
    |> Ecto.Multi.run(:users, fn _repo, _changes ->
      insert_csv_users(csv_rows)
    end)
    |> Ecto.Multi.run(:profiles, fn _repo, changes ->
      insert_csv_profiles(changes, csv_rows, "staff")
    end)
    |> Ecto.Multi.run(:response, fn _repo, changes ->
      format_response(changes, csv_rows, "staff")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes.response}
      error_tuple -> error_tuple
    end
  end

  defp insert_csv_staff_members(csv_rows, school_id) do
    name_staff_member_map =
      csv_rows
      |> Enum.map(&get_or_insert_csv_staff_member(&1, school_id))
      |> Enum.filter(fn
        {:ok, _staff_member} -> true
        {:error, _changeset} -> false
      end)
      |> Enum.map(fn {:ok, staff_member} -> {staff_member.name, staff_member} end)
      |> Enum.into(%{})

    {:ok, name_staff_member_map}
  end

  defp get_or_insert_csv_staff_member(csv_row, school_id) do
    case Repo.get_by(StaffMember, name: csv_row.name, school_id: school_id) do
      nil ->
        %{
          name: csv_row.name,
          school_id: school_id
        }
        |> create_staff_member()

      staff_member ->
        {:ok, staff_member}
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
        "staff" -> changes.staff_members
      end

    email_user_map = changes.users

    profiles =
      csv_rows
      |> Enum.filter(&(&1.email != "" && &1.name != ""))
      |> Enum.map(
        &%{
          type: type,
          staff_member_id:
            if(type == "staff",
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
        "staff" -> changes.staff_members
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
end
