defmodule LantternWeb.CurriculumRelationshipController do
  use LantternWeb, :controller

  import LantternWeb.CurriculaHelpers
  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumRelationship

  def index(conn, _params) do
    curriculum_relationships =
      Curricula.list_curriculum_relationships(preloads: [:curriculum_item_a, :curriculum_item_b])

    render(conn, :index, curriculum_relationships: curriculum_relationships)
  end

  def new(conn, _params) do
    options = generate_curriculum_item_options()
    changeset = Curricula.change_curriculum_relationship(%CurriculumRelationship{})
    render(conn, :new, curriculum_item_options: options, changeset: changeset)
  end

  def create(conn, %{"curriculum_relationship" => curriculum_relationship_params}) do
    case Curricula.create_curriculum_relationship(curriculum_relationship_params) do
      {:ok, curriculum_relationship} ->
        conn
        |> put_flash(:info, "Curriculum relationship created successfully.")
        |> redirect(to: ~p"/admin/curriculum_relationships/#{curriculum_relationship}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_item_options()
        render(conn, :new, curriculum_item_options: options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum_relationship =
      Curricula.get_curriculum_relationship!(id,
        preloads: [:curriculum_item_a, :curriculum_item_b]
      )

    render(conn, :show, curriculum_relationship: curriculum_relationship)
  end

  def edit(conn, %{"id" => id}) do
    curriculum_relationship = Curricula.get_curriculum_relationship!(id)
    options = generate_curriculum_item_options()
    changeset = Curricula.change_curriculum_relationship(curriculum_relationship)

    render(conn, :edit,
      curriculum_relationship: curriculum_relationship,
      curriculum_item_options: options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "curriculum_relationship" => curriculum_relationship_params}) do
    curriculum_relationship = Curricula.get_curriculum_relationship!(id)

    case Curricula.update_curriculum_relationship(
           curriculum_relationship,
           curriculum_relationship_params
         ) do
      {:ok, curriculum_relationship} ->
        conn
        |> put_flash(:info, "Curriculum relationship updated successfully.")
        |> redirect(to: ~p"/admin/curriculum_relationships/#{curriculum_relationship}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_curriculum_item_options()

        render(conn, :edit,
          curriculum_relationship: curriculum_relationship,
          curriculum_item_options: options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    curriculum_relationship = Curricula.get_curriculum_relationship!(id)

    {:ok, _curriculum_relationship} =
      Curricula.delete_curriculum_relationship(curriculum_relationship)

    conn
    |> put_flash(:info, "Curriculum relationship deleted successfully.")
    |> redirect(to: ~p"/admin/curriculum_relationships")
  end
end
