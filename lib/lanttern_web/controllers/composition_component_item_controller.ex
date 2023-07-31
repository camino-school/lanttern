defmodule LantternWeb.CompositionComponentItemController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.CompositionComponentItem

  def index(conn, _params) do
    component_items = Grading.list_component_items()
    render(conn, :index, component_items: component_items)
  end

  def new(conn, _params) do
    changeset = Grading.change_composition_component_item(%CompositionComponentItem{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"composition_component_item" => composition_component_item_params}) do
    case Grading.create_composition_component_item(composition_component_item_params) do
      {:ok, composition_component_item} ->
        conn
        |> put_flash(:info, "Composition component item created successfully.")
        |> redirect(to: ~p"/grading/component_items/#{composition_component_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    composition_component_item = Grading.get_composition_component_item!(id)
    render(conn, :show, composition_component_item: composition_component_item)
  end

  def edit(conn, %{"id" => id}) do
    composition_component_item = Grading.get_composition_component_item!(id)
    changeset = Grading.change_composition_component_item(composition_component_item)

    render(conn, :edit,
      composition_component_item: composition_component_item,
      changeset: changeset
    )
  end

  def update(conn, %{
        "id" => id,
        "composition_component_item" => composition_component_item_params
      }) do
    composition_component_item = Grading.get_composition_component_item!(id)

    case Grading.update_composition_component_item(
           composition_component_item,
           composition_component_item_params
         ) do
      {:ok, composition_component_item} ->
        conn
        |> put_flash(:info, "Composition component item updated successfully.")
        |> redirect(to: ~p"/grading/component_items/#{composition_component_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          composition_component_item: composition_component_item,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    composition_component_item = Grading.get_composition_component_item!(id)

    {:ok, _composition_component_item} =
      Grading.delete_composition_component_item(composition_component_item)

    conn
    |> put_flash(:info, "Composition component item deleted successfully.")
    |> redirect(to: ~p"/grading/component_items")
  end
end
