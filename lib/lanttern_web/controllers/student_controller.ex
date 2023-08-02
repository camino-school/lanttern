defmodule LantternWeb.StudentController do
  use LantternWeb, :controller

  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  def index(conn, _params) do
    students = Schools.list_students()
    render(conn, :index, students: students)
  end

  def new(conn, _params) do
    changeset = Schools.change_student(%Student{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"student" => student_params}) do
    case Schools.create_student(student_params) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Student created successfully.")
        |> redirect(to: ~p"/schools/students/#{student}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    student = Schools.get_student!(id)
    render(conn, :show, student: student)
  end

  def edit(conn, %{"id" => id}) do
    student = Schools.get_student!(id)
    changeset = Schools.change_student(student)
    render(conn, :edit, student: student, changeset: changeset)
  end

  def update(conn, %{"id" => id, "student" => student_params}) do
    student = Schools.get_student!(id)

    case Schools.update_student(student, student_params) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Student updated successfully.")
        |> redirect(to: ~p"/schools/students/#{student}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, student: student, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    student = Schools.get_student!(id)
    {:ok, _student} = Schools.delete_student(student)

    conn
    |> put_flash(:info, "Student deleted successfully.")
    |> redirect(to: ~p"/schools/students")
  end
end
