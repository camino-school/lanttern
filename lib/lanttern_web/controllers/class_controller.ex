defmodule LantternWeb.ClassController do
  use LantternWeb, :controller

  import LantternWeb.SchoolsHelpers
  alias Lanttern.Schools
  alias Lanttern.Schools.Class

  def index(conn, _params) do
    classes = Schools.list_classes(preloads: :students)
    render(conn, :index, classes: classes)
  end

  def new(conn, _params) do
    changeset = Schools.change_class(%Class{})
    student_options = generate_student_options()
    render(conn, :new, student_options: student_options, changeset: changeset)
  end

  def create(conn, %{"class" => class_params}) do
    case Schools.create_class(class_params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class created successfully.")
        |> redirect(to: ~p"/admin/schools/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        student_options = generate_student_options()
        render(conn, :new, student_options: student_options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    class = Schools.get_class!(id, preloads: :students)
    render(conn, :show, class: class)
  end

  def edit(conn, %{"id" => id}) do
    student_options = generate_student_options()

    class = Schools.get_class!(id, preloads: :students)

    # insert existing students_ids
    students_ids = Enum.map(class.students, & &1.id)
    class = class |> Map.put(:students_ids, students_ids)

    changeset = Schools.change_class(class)
    render(conn, :edit, class: class, student_options: student_options, changeset: changeset)
  end

  def update(conn, %{"id" => id, "class" => class_params}) do
    class = Schools.get_class!(id)

    case Schools.update_class(class, class_params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class updated successfully.")
        |> redirect(to: ~p"/admin/schools/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        student_options = generate_student_options()

        render(conn, :edit,
          class: class,
          student_options: student_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    class = Schools.get_class!(id)
    {:ok, _class} = Schools.delete_class(class)

    conn
    |> put_flash(:info, "Class deleted successfully.")
    |> redirect(to: ~p"/admin/schools/classes")
  end
end
