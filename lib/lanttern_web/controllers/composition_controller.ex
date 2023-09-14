defmodule LantternWeb.CompositionController do
  use LantternWeb, :controller

  import LantternWeb.GradingHelpers
  alias Lanttern.Grading
  alias Lanttern.Grading.Composition

  def index(conn, _params) do
    compositions = Grading.list_compositions(:final_grade_scale)
    render(conn, :index, compositions: compositions)
  end

  def new(conn, _params) do
    options = generate_scale_options()
    changeset = Grading.change_composition(%Composition{})
    render(conn, :new, scale_options: options, changeset: changeset)
  end

  def create(conn, %{"composition" => composition_params}) do
    case Grading.create_composition(composition_params) do
      {:ok, composition} ->
        conn
        |> put_flash(:info, "Composition created successfully.")
        |> redirect(to: ~p"/admin/grading_compositions/#{composition}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()
        render(conn, :new, scale_options: options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id, :final_grade_scale)
    render(conn, :show, composition: composition)
  end

  def edit(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id)
    options = generate_scale_options()
    changeset = Grading.change_composition(composition)
    render(conn, :edit, composition: composition, scale_options: options, changeset: changeset)
  end

  def update(conn, %{"id" => id, "composition" => composition_params}) do
    composition = Grading.get_composition!(id)

    case Grading.update_composition(composition, composition_params) do
      {:ok, composition} ->
        conn
        |> put_flash(:info, "Composition updated successfully.")
        |> redirect(to: ~p"/admin/grading_compositions/#{composition}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()

        render(conn, :edit,
          composition: composition,
          scale_options: options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    composition = Grading.get_composition!(id)
    {:ok, _composition} = Grading.delete_composition(composition)

    conn
    |> put_flash(:info, "Composition deleted successfully.")
    |> redirect(to: ~p"/admin/grading_compositions")
  end
end
