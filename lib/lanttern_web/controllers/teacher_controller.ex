defmodule LantternWeb.TeacherController do
  use LantternWeb, :controller

  import LantternWeb.SchoolsHelpers
  alias Lanttern.Schools
  alias Lanttern.Schools.Teacher

  def index(conn, _params) do
    teachers = Schools.list_teachers(preloads: :school)
    render(conn, :index, teachers: teachers)
  end

  def new(conn, _params) do
    school_options = generate_school_options()
    changeset = Schools.change_teacher(%Teacher{})
    render(conn, :new, school_options: school_options, changeset: changeset)
  end

  def create(conn, %{"teacher" => teacher_params}) do
    case Schools.create_teacher(teacher_params) do
      {:ok, teacher} ->
        conn
        |> put_flash(:info, "Teacher created successfully.")
        |> redirect(to: ~p"/admin/teachers/#{teacher}")

      {:error, %Ecto.Changeset{} = changeset} ->
        school_options = generate_school_options()
        render(conn, :new, school_options: school_options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    teacher = Schools.get_teacher!(id, preloads: :school)
    render(conn, :show, teacher: teacher)
  end

  def edit(conn, %{"id" => id}) do
    teacher = Schools.get_teacher!(id)
    school_options = generate_school_options()
    changeset = Schools.change_teacher(teacher)
    render(conn, :edit, teacher: teacher, school_options: school_options, changeset: changeset)
  end

  def update(conn, %{"id" => id, "teacher" => teacher_params}) do
    teacher = Schools.get_teacher!(id)

    case Schools.update_teacher(teacher, teacher_params) do
      {:ok, teacher} ->
        conn
        |> put_flash(:info, "Teacher updated successfully.")
        |> redirect(to: ~p"/admin/teachers/#{teacher}")

      {:error, %Ecto.Changeset{} = changeset} ->
        school_options = generate_school_options()

        render(conn, :edit,
          teacher: teacher,
          school_options: school_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    teacher = Schools.get_teacher!(id)
    {:ok, _teacher} = Schools.delete_teacher(teacher)

    conn
    |> put_flash(:info, "Teacher deleted successfully.")
    |> redirect(to: ~p"/admin/teachers")
  end
end
