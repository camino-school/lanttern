defmodule LantternWeb.CompositionComponentController do
  use LantternWeb, :controller

  import LantternWeb.GradingHelpers
  alias Lanttern.Grading
  alias Lanttern.Grading.CompositionComponent

  def index(conn, _params) do
    composition_components = Grading.list_composition_components(:composition)
    render(conn, :index, composition_components: composition_components)
  end

  def new(conn, _params) do
    changeset = Grading.change_composition_component(%CompositionComponent{})
    options = generate_composition_options()
    render(conn, :new, changeset: changeset, composition_options: options)
  end

  def create(conn, %{"composition_component" => composition_component_params}) do
    case Grading.create_composition_component(composition_component_params) do
      {:ok, composition_component} ->
        conn
        |> put_flash(:info, "Composition component created successfully.")
        |> redirect(to: ~p"/admin/grading_composition_components/#{composition_component}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_composition_options()
        render(conn, :new, changeset: changeset, composition_options: options)
    end
  end

  def show(conn, %{"id" => id}) do
    composition_component = Grading.get_composition_component!(id, :composition)
    render(conn, :show, composition_component: composition_component)
  end

  def edit(conn, %{"id" => id}) do
    composition_component = Grading.get_composition_component!(id)
    changeset = Grading.change_composition_component(composition_component)
    options = generate_composition_options()

    render(conn, :edit,
      composition_component: composition_component,
      changeset: changeset,
      composition_options: options
    )
  end

  def update(conn, %{"id" => id, "composition_component" => composition_component_params}) do
    composition_component = Grading.get_composition_component!(id)

    case Grading.update_composition_component(composition_component, composition_component_params) do
      {:ok, composition_component} ->
        conn
        |> put_flash(:info, "Composition component updated successfully.")
        |> redirect(to: ~p"/admin/grading_composition_components/#{composition_component}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_composition_options()

        render(conn, :edit,
          composition_component: composition_component,
          changeset: changeset,
          composition_options: options
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    composition_component = Grading.get_composition_component!(id)
    {:ok, _composition_component} = Grading.delete_composition_component(composition_component)

    conn
    |> put_flash(:info, "Composition component deleted successfully.")
    |> redirect(to: ~p"/admin/grading_composition_components")
  end
end
