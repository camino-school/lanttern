defmodule LantternWeb.CurriculumItemController do
  use LantternWeb, :controller

  import LantternWeb.CurriculaHelpers
  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem

  def index(conn, _params) do
    curriculum_items = Curricula.list_curriculum_items(preloads: :curriculum_component)
    render(conn, :index, curriculum_items: curriculum_items)
  end

  def new(conn, _params) do
    options = generate_curriculum_component_options()
    changeset = Curricula.change_curriculum_item(%CurriculumItem{})
    render(conn, :new, curriculum_component_options: options, changeset: changeset)
  end

  def create(conn, %{"curriculum_item" => curriculum_item_params}) do
    case Curricula.create_curriculum_item(curriculum_item_params) do
      {:ok, curriculum_item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_items/#{curriculum_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_component_options()
        render(conn, :new, curriculum_component_options: options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum_item = Curricula.get_curriculum_item!(id, preloads: :curriculum_component)
    render(conn, :show, curriculum_item: curriculum_item)
  end

  def edit(conn, %{"id" => id}) do
    curriculum_item = Curricula.get_curriculum_item!(id)
    options = generate_curriculum_component_options()
    changeset = Curricula.change_curriculum_item(curriculum_item)

    render(conn, :edit,
      curriculum_item: curriculum_item,
      curriculum_component_options: options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "curriculum_item" => curriculum_item_params}) do
    curriculum_item = Curricula.get_curriculum_item!(id)

    case Curricula.update_curriculum_item(curriculum_item, curriculum_item_params) do
      {:ok, curriculum_item} ->
        conn
        |> put_flash(:info, "Curriculum item updated successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_items/#{curriculum_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_component_options()

        render(conn, :edit,
          curriculum_item: curriculum_item,
          curriculum_component_options: options,
          changeset: changeset
        )
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
