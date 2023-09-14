defmodule LantternWeb.CurriculumController do
  use LantternWeb, :controller

  alias Lanttern.Curricula
  alias Lanttern.Curricula.Curriculum

  def index(conn, _params) do
    curricula = Curricula.list_curricula()
    render(conn, :index, curricula: curricula)
  end

  def new(conn, _params) do
    changeset = Curricula.change_curriculum(%Curriculum{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"curriculum" => curriculum_params}) do
    case Curricula.create_curriculum(curriculum_params) do
      {:ok, curriculum} ->
        conn
        |> put_flash(:info, "Curriculum created successfully.")
        |> redirect(to: ~p"/admin/curricula/#{curriculum}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum = Curricula.get_curriculum!(id)
    render(conn, :show, curriculum: curriculum)
  end

  def edit(conn, %{"id" => id}) do
    curriculum = Curricula.get_curriculum!(id)
    changeset = Curricula.change_curriculum(curriculum)
    render(conn, :edit, curriculum: curriculum, changeset: changeset)
  end

  def update(conn, %{"id" => id, "curriculum" => curriculum_params}) do
    curriculum = Curricula.get_curriculum!(id)

    case Curricula.update_curriculum(curriculum, curriculum_params) do
      {:ok, curriculum} ->
        conn
        |> put_flash(:info, "Curriculum updated successfully.")
        |> redirect(to: ~p"/admin/curricula/#{curriculum}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, curriculum: curriculum, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    curriculum = Curricula.get_curriculum!(id)
    {:ok, _curriculum} = Curricula.delete_curriculum(curriculum)

    conn
    |> put_flash(:info, "Curriculum deleted successfully.")
    |> redirect(to: ~p"/admin/curricula")
  end
end
