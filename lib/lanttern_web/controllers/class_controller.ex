defmodule LantternWeb.ClassController do
  use LantternWeb, :controller

  import LantternWeb.SchoolsHelpers
  import LantternWeb.TaxonomyHelpers
  alias Lanttern.Schools
  alias Lanttern.Schools.Class

  def index(conn, _params) do
    classes = Schools.list_classes(preloads: [:school, :cycle, :years, :students, :staff_members])
    render(conn, :index, classes: classes)
  end

  def new(conn, _params) do
    changeset = Schools.change_class(%Class{}, %{current_profile: %{school_id: nil}})
    student_options = generate_student_options()
    staff_member_options = generate_staff_member_options()
    school_options = generate_school_options()
    cycle_options = generate_cycle_options()
    year_options = generate_year_options()

    render(conn, :new,
      school_options: school_options,
      cycle_options: cycle_options,
      year_options: year_options,
      student_options: student_options,
      staff_member_options: staff_member_options,
      changeset: changeset
    )
  end

  def create(conn, %{"class" => class_params}) do
    case Schools.create_class(class_params, %{
           current_profile: %{school_id: class_params["school_id"]}
         }) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class created successfully.")
        |> redirect(to: ~p"/admin/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        student_options = generate_student_options()
        staff_member_options = generate_staff_member_options()
        school_options = generate_school_options()
        cycle_options = generate_cycle_options()
        year_options = generate_year_options()

        render(conn, :new,
          school_options: school_options,
          cycle_options: cycle_options,
          year_options: year_options,
          student_options: student_options,
          staff_member_options: staff_member_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    class = Schools.get_class!(id, preloads: [:school, :cycle, :years, :students, :staff_members])
    render(conn, :show, class: class)
  end

  def edit(conn, %{"id" => id}) do
    school_options = generate_school_options()
    student_options = generate_student_options()
    staff_member_options = generate_staff_member_options()
    cycle_options = generate_cycle_options()
    year_options = generate_year_options()

    class = Schools.get_class!(id, preloads: [:students, :years, :staff_members])

    # insert existing students_ids, years_ids and staff_members_ids
    students_ids = Enum.map(class.students, & &1.id)
    years_ids = Enum.map(class.years, & &1.id)
    staff_members_ids = Enum.map(class.staff_members, & &1.id)

    class =
      class
      |> Map.put(:students_ids, students_ids)
      |> Map.put(:years_ids, years_ids)
      |> Map.put(:staff_members_ids, staff_members_ids)

    changeset = Schools.change_class(class, %{current_profile: %{school_id: class.school_id}})

    render(conn, :edit,
      class: class,
      school_options: school_options,
      cycle_options: cycle_options,
      year_options: year_options,
      student_options: student_options,
      staff_member_options: staff_member_options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "class" => class_params}) do
    class = Schools.get_class!(id)

    case Schools.update_class(class, class_params, %{
           current_profile: %{school_id: class.school_id}
         }) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class updated successfully.")
        |> redirect(to: ~p"/admin/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        school_options = generate_school_options()
        cycle_options = generate_cycle_options()
        year_options = generate_year_options()
        student_options = generate_student_options()
        staff_member_options = generate_staff_member_options()

        render(conn, :edit,
          class: class,
          school_options: school_options,
          cycle_options: cycle_options,
          year_options: year_options,
          student_options: student_options,
          staff_member_options: staff_member_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    class = Schools.get_class!(id)
    {:ok, _class} = Schools.delete_class(class)

    conn
    |> put_flash(:info, "Class deleted successfully.")
    |> redirect(to: ~p"/admin/classes")
  end
end
