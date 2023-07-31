defmodule LantternWeb.CompositionController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.Composition

  def index(conn, _params) do
    compositions = Grading.list_compositions()
    render(conn, :index, compositions: compositions)
  end

  def new(conn, _params) do
    changeset = Grading.change_composition(%Composition{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"composition" => composition_params}) do
    case Grading.create_composition(composition_params) do
      {:ok, composition} ->
        conn
        |> put_flash(:info, "Composition created successfully.")
        |> redirect(to: ~p"/grading/compositions/#{composition}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id)
    render(conn, :show, composition: composition)
  end

  def edit(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id)
    changeset = Grading.change_composition(composition)
    render(conn, :edit, composition: composition, changeset: changeset)
  end

  def update(conn, %{"id" => id, "composition" => composition_params}) do
    composition = Grading.get_composition!(id)

    case Grading.update_composition(composition, composition_params) do
      {:ok, composition} ->
        conn
        |> put_flash(:info, "Composition updated successfully.")
        |> redirect(to: ~p"/grading/compositions/#{composition}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, composition: composition, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id)
    {:ok, _composition} = Grading.delete_composition(composition)

    conn
    |> put_flash(:info, "Composition deleted successfully.")
    |> redirect(to: ~p"/grading/compositions")
  end
end
