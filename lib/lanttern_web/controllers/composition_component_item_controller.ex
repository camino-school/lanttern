defmodule LantternWeb.CompositionComponentItemController do
  use LantternWeb, :controller

  alias Lanttern.Curricula
  alias Lanttern.Grading
  alias Lanttern.Grading.CompositionComponentItem

  def index(conn, _params) do
    component_items = Grading.list_component_items([:component, :curriculum_item])
    render(conn, :index, component_items: component_items)
  end

  def new(conn, _params) do
    component_options = generate_component_options()
    curriculum_item_options = generate_curriculum_item_options()
    changeset = Grading.change_composition_component_item(%CompositionComponentItem{})

    render(conn, :new,
      component_options: component_options,
      curriculum_item_options: curriculum_item_options,
      changeset: changeset
    )
  end

  def create(conn, %{"composition_component_item" => composition_component_item_params}) do
    case Grading.create_composition_component_item(composition_component_item_params) do
      {:ok, composition_component_item} ->
        conn
        |> put_flash(:info, "Composition component item created successfully.")
        |> redirect(to: ~p"/grading/component_items/#{composition_component_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        component_options = generate_component_options()
        curriculum_item_options = generate_curriculum_item_options()

        render(conn, :new,
          component_options: component_options,
          curriculum_item_options: curriculum_item_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    composition_component_item =
      Grading.get_composition_component_item!(id, [:component, :curriculum_item])

    render(conn, :show, composition_component_item: composition_component_item)
  end

  def edit(conn, %{"id" => id}) do
    composition_component_item = Grading.get_composition_component_item!(id)
    component_options = generate_component_options()
    curriculum_item_options = generate_curriculum_item_options()
    changeset = Grading.change_composition_component_item(composition_component_item)

    render(conn, :edit,
      composition_component_item: composition_component_item,
      component_options: component_options,
      curriculum_item_options: curriculum_item_options,
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
        component_options = generate_component_options()
        curriculum_item_options = generate_curriculum_item_options()

        render(conn, :edit,
          composition_component_item: composition_component_item,
          component_options: component_options,
          curriculum_item_options: curriculum_item_options,
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

  defp generate_component_options() do
    Grading.list_composition_components()
    |> Enum.map(fn c -> ["#{c.name}": c.id] end)
    |> Enum.concat()
  end

  defp generate_curriculum_item_options() do
    Curricula.list_items()
    |> Enum.map(fn i -> ["#{i.name}": i.id] end)
    |> Enum.concat()
  end
end
