defmodule LantternWeb.SchoolController do
  use LantternWeb, :controller

  alias Lanttern.Schools
  alias Lanttern.Schools.School

  def index(conn, _params) do
    schools = Schools.list_schools()
    render(conn, :index, schools: schools)
  end

  def new(conn, _params) do
    changeset = Schools.change_school(%School{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"school" => school_params}) do
    case Schools.create_school(school_params) do
      {:ok, school} ->
        conn
        |> put_flash(:info, "School created successfully.")
        |> redirect(to: ~p"/admin/schools/schools/#{school}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    school = Schools.get_school!(id)
    render(conn, :show, school: school)
  end

  def edit(conn, %{"id" => id}) do
    school = Schools.get_school!(id)
    changeset = Schools.change_school(school)
    render(conn, :edit, school: school, changeset: changeset)
  end

  def update(conn, %{"id" => id, "school" => school_params}) do
    school = Schools.get_school!(id)

    case Schools.update_school(school, school_params) do
      {:ok, school} ->
        conn
        |> put_flash(:info, "School updated successfully.")
        |> redirect(to: ~p"/admin/schools/schools/#{school}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, school: school, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    school = Schools.get_school!(id)
    {:ok, _school} = Schools.delete_school(school)

    conn
    |> put_flash(:info, "School deleted successfully.")
    |> redirect(to: ~p"/admin/schools/schools")
  end
end
