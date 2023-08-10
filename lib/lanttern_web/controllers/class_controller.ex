defmodule LantternWeb.ClassController do
  use LantternWeb, :controller

  alias Lanttern.Schools
  alias Lanttern.Schools.Class

  def index(conn, _params) do
    classes = Schools.list_classes()
    render(conn, :index, classes: classes)
  end

  def new(conn, _params) do
    changeset = Schools.change_class(%Class{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"class" => class_params}) do
    case Schools.create_class(class_params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class created successfully.")
        |> redirect(to: ~p"/admin/schools/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    class = Schools.get_class!(id)
    render(conn, :show, class: class)
  end

  def edit(conn, %{"id" => id}) do
    class = Schools.get_class!(id)
    changeset = Schools.change_class(class)
    render(conn, :edit, class: class, changeset: changeset)
  end

  def update(conn, %{"id" => id, "class" => class_params}) do
    class = Schools.get_class!(id)

    case Schools.update_class(class, class_params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class updated successfully.")
        |> redirect(to: ~p"/admin/schools/classes/#{class}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, class: class, changeset: changeset)
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
