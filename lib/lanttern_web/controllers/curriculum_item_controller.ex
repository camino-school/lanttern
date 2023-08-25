defmodule LantternWeb.CurriculumItemController do
  use LantternWeb, :controller

  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem

  def index(conn, _params) do
    curriculum_items = Curricula.list_curriculum_items()
    render(conn, :index, curriculum_items: curriculum_items)
  end

  def new(conn, _params) do
    changeset = Curricula.change_curriculum_item(%CurriculumItem{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"curriculum_item" => curriculum_item_params}) do
    case Curricula.create_curriculum_item(curriculum_item_params) do
      {:ok, curriculum_item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_items/#{curriculum_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum_item = Curricula.get_curriculum_item!(id)
    render(conn, :show, curriculum_item: curriculum_item)
  end

  def edit(conn, %{"id" => id}) do
    curriculum_item = Curricula.get_curriculum_item!(id)
    changeset = Curricula.change_curriculum_item(curriculum_item)
    render(conn, :edit, curriculum_item: curriculum_item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "curriculum_item" => curriculum_item_params}) do
    curriculum_item = Curricula.get_curriculum_item!(id)

    case Curricula.update_curriculum_item(curriculum_item, curriculum_item_params) do
      {:ok, curriculum_item} ->
        conn
        |> put_flash(:info, "Curriculum item updated successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_items/#{curriculum_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, curriculum_item: curriculum_item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    curriculum_item = Curricula.get_curriculum_item!(id)
    {:ok, _curriculum_item} = Curricula.delete_curriculum_item(curriculum_item)

    conn
    |> put_flash(:info, "Curriculum item deleted successfully.")
    |> redirect(to: ~p"/admin/curricula/curriculum_items")
  end
end
