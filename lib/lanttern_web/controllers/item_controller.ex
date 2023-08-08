defmodule LantternWeb.ItemController do
  use LantternWeb, :controller

  alias Lanttern.Curricula
  alias Lanttern.Curricula.Item

  def index(conn, _params) do
    items = Curricula.list_items()
    render(conn, :index, items: items)
  end

  def new(conn, _params) do
    changeset = Curricula.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case Curricula.create_item(item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: ~p"/admin/curricula/items/#{item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    item = Curricula.get_item!(id)
    render(conn, :show, item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Curricula.get_item!(id)
    changeset = Curricula.change_item(item)
    render(conn, :edit, item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Curricula.get_item!(id)

    case Curricula.update_item(item, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item updated successfully.")
        |> redirect(to: ~p"/admin/curricula/items/#{item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Curricula.get_item!(id)
    {:ok, _item} = Curricula.delete_item(item)

    conn
    |> put_flash(:info, "Item deleted successfully.")
    |> redirect(to: ~p"/admin/curricula/items")
  end
end
