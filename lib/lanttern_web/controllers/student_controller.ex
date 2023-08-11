defmodule LantternWeb.StudentController do
  use LantternWeb, :controller

  import LantternWeb.SchoolsHelpers
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  def index(conn, _params) do
    students = Schools.list_students(:classes)
    render(conn, :index, students: students)
  end

  def new(conn, _params) do
    class_options = generate_class_options()
    changeset = Schools.change_student(%Student{})
    render(conn, :new, class_options: class_options, changeset: changeset)
  end

  def create(conn, %{"student" => student_params}) do
    case Schools.create_student(student_params) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Student created successfully.")
        |> redirect(to: ~p"/admin/schools/students/#{student}")

      {:error, %Ecto.Changeset{} = changeset} ->
        class_options = generate_class_options()
        render(conn, :new, class_options: class_options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    student = Schools.get_student!(id, :classes)
    render(conn, :show, student: student)
  end

  def edit(conn, %{"id" => id}) do
    class_options = generate_class_options()
    student = Schools.get_student!(id, :classes)

    # insert existing classes_ids
    classes_ids = Enum.map(student.classes, & &1.id)
    student = student |> Map.put(:classes_ids, classes_ids)

    changeset = Schools.change_student(student)
    render(conn, :edit, class_options: class_options, student: student, changeset: changeset)
  end

  def update(conn, %{"id" => id, "student" => student_params}) do
    student = Schools.get_student!(id)

    case Schools.update_student(student, student_params) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Student updated successfully.")
        |> redirect(to: ~p"/admin/schools/students/#{student}")

      {:error, %Ecto.Changeset{} = changeset} ->
        class_options = generate_class_options()
        render(conn, :edit, class_options: class_options, student: student, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    student = Schools.get_student!(id)
    {:ok, _student} = Schools.delete_student(student)

    conn
    |> put_flash(:info, "Student deleted successfully.")
    |> redirect(to: ~p"/admin/schools/students")
  end
end
