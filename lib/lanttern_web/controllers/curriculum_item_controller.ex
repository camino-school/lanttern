defmodule LantternWeb.CurriculumItemController do
  use LantternWeb, :controller

  import LantternWeb.CurriculaHelpers
  import LantternWeb.TaxonomyHelpers
  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem

  def index(conn, %{"q" => ""} = _params),
    do: redirect(conn, to: ~p"/admin/curricula/curriculum_items")

  def index(conn, %{"q" => query} = _params) do
    curriculum_items =
      Curricula.search_curriculum_items(query,
        preloads: [:curriculum_component, :subjects, :years]
      )

    form = Phoenix.Component.to_form(%{"q" => query})

    render(conn, :index, curriculum_items: curriculum_items, form: form)
  end

  def index(conn, _params) do
    curriculum_items =
      Curricula.list_curriculum_items(preloads: [:curriculum_component, :subjects, :years])

    form = Phoenix.Component.to_form(%{"q" => ""})

    render(conn, :index, curriculum_items: curriculum_items, form: form)
  end

  def new(conn, _params) do
    curriculum_component_options = generate_curriculum_component_options()
    subject_options = generate_subject_options()
    year_options = generate_year_options()
    changeset = Curricula.change_curriculum_item(%CurriculumItem{})

    render(conn, :new,
      curriculum_component_options: curriculum_component_options,
      subject_options: subject_options,
      year_options: year_options,
      changeset: changeset
    )
  end

  def create(conn, %{"curriculum_item" => curriculum_item_params}) do
    case Curricula.create_curriculum_item(curriculum_item_params) do
      {:ok, curriculum_item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: ~p"/admin/curricula/curriculum_items/#{curriculum_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        curriculum_component_options = generate_curriculum_component_options()
        subject_options = generate_subject_options()
        year_options = generate_year_options()

        render(conn, :new,
          curriculum_component_options: curriculum_component_options,
          subject_options: subject_options,
          year_options: year_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    curriculum_item =
      Curricula.get_curriculum_item!(id, preloads: [:curriculum_component, :subjects, :years])

    render(conn, :show, curriculum_item: curriculum_item)
  end

  def edit(conn, %{"id" => id}) do
    curriculum_component_options = generate_curriculum_component_options()
    subject_options = generate_subject_options()
    year_options = generate_year_options()

    curriculum_item = Curricula.get_curriculum_item!(id, preloads: [:subjects, :years])

    # insert existing subjects_ids
    subjects_ids = Enum.map(curriculum_item.subjects, & &1.id)
    curriculum_item = curriculum_item |> Map.put(:subjects_ids, subjects_ids)

    # insert existing years_ids
    years_ids = Enum.map(curriculum_item.years, & &1.id)
    curriculum_item = curriculum_item |> Map.put(:years_ids, years_ids)

    changeset = Curricula.change_curriculum_item(curriculum_item)

    render(conn, :edit,
      curriculum_item: curriculum_item,
      curriculum_component_options: curriculum_component_options,
      subject_options: subject_options,
      year_options: year_options,
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
        curriculum_component_options = generate_curriculum_component_options()
        subject_options = generate_subject_options()
        year_options = generate_year_options()

        render(conn, :edit,
          curriculum_item: curriculum_item,
          curriculum_component_options: curriculum_component_options,
          subject_options: subject_options,
          year_options: year_options,
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
