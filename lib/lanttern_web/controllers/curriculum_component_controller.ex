defmodule LantternWeb.CurriculumComponentController do
  use LantternWeb, :controller

  import LantternWeb.CurriculaHelpers
  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumComponent

  def index(conn, _params) do
    curriculum_components = Curricula.list_curriculum_components(preloads: :curriculum)
    render(conn, :index, curriculum_components: curriculum_components)
  end

  def new(conn, _params) do
    changeset = Curricula.change_curriculum_component(%CurriculumComponent{})
    options = generate_curriculum_options()
    render(conn, :new, changeset: changeset, curriculum_options: options)
  end

  def create(conn, %{"curriculum_component" => curriculum_component_params}) do
    case Curricula.create_curriculum_component(curriculum_component_params) do
      {:ok, curriculum_component} ->
        conn
        |> put_flash(:info, "Curriculum component created successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_components/#{curriculum_component}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_options()
        render(conn, :new, changeset: changeset, curriculum_options: options)
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum_component = Curricula.get_curriculum_component!(id, preloads: :curriculum)
    render(conn, :show, curriculum_component: curriculum_component)
  end

  def edit(conn, %{"id" => id}) do
    curriculum_component = Curricula.get_curriculum_component!(id)
    changeset = Curricula.change_curriculum_component(curriculum_component)
    options = generate_curriculum_options()

    render(conn, :edit,
      curriculum_component: curriculum_component,
      changeset: changeset,
      curriculum_options: options
    )
  end

  def update(conn, %{"id" => id, "curriculum_component" => curriculum_component_params}) do
    curriculum_component = Curricula.get_curriculum_component!(id)

    case Curricula.update_curriculum_component(curriculum_component, curriculum_component_params) do
      {:ok, curriculum_component} ->
        conn
        |> put_flash(:info, "Curriculum component updated successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_components/#{curriculum_component}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_options()

        render(conn, :edit,
          curriculum_component: curriculum_component,
          changeset: changeset,
          curriculum_options: options
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    curriculum_component = Curricula.get_curriculum_component!(id)
    {:ok, _curriculum_component} = Curricula.delete_curriculum_component(curriculum_component)

    conn
    |> put_flash(:info, "Curriculum component deleted successfully.")
    |> redirect(to: ~p"/admin/curricula/curriculum_components")
  end
end
