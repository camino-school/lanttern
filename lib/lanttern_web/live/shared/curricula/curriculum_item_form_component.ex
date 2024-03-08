defmodule LantternWeb.Curricula.CurriculumItemFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Curricula
  alias Lanttern.Taxonomy

  # live components
  alias LantternWeb.BadgeButtonPickerComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="curriculum-item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:code]}
          type="text"
          label={gettext("Code")}
          class="mb-6"
          phx-debounce="1500"
          show_optional
        />
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <div class="mb-6">
          <.label><%= gettext("Subjects") %></.label>
          <.live_component
            module={BadgeButtonPickerComponent}
            id="curriculum-item-subjects-select"
            on_select={&JS.push("toggle_subject", value: %{"id" => &1}, target: @myself)}
            items={@subjects}
            selected_ids={@selected_subjects_ids}
          />
        </div>
        <div class="mb-6">
          <.label><%= gettext("Years") %></.label>
          <.live_component
            module={BadgeButtonPickerComponent}
            id="curriculum-item-years-select"
            on_select={&JS.push("toggle_year", value: %{"id" => &1}, target: @myself)}
            items={@years}
            selected_ids={@selected_years_ids}
          />
        </div>
        <.button :if={!@hide_submit} type="submit" phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save curriculum item") %>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:hide_submit, false)
      |> assign(:is_admin, false)

    {:ok, socket}
  end

  @impl true
  def update(%{curriculum_item: curriculum_item} = assigns, socket) do
    changeset = Curricula.change_curriculum_item(curriculum_item)

    selected_subjects_ids =
      curriculum_item
      |> Map.get(:subjects, [])
      |> Enum.map(& &1.id)

    selected_years_ids =
      curriculum_item
      |> Map.get(:years, [])
      |> Enum.map(& &1.id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:subjects, Taxonomy.list_subjects())
      |> assign(:selected_subjects_ids, selected_subjects_ids)
      |> assign(:years, Taxonomy.list_years())
      |> assign(:selected_years_ids, selected_years_ids)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_subject", %{"id" => id}, socket) do
    selected_subjects_ids =
      case id in socket.assigns.selected_subjects_ids do
        true ->
          socket.assigns.selected_subjects_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_subjects_ids]
      end

    {:noreply, assign(socket, :selected_subjects_ids, selected_subjects_ids)}
  end

  def handle_event("toggle_year", %{"id" => id}, socket) do
    selected_years_ids =
      case id in socket.assigns.selected_years_ids do
        true ->
          socket.assigns.selected_years_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_years_ids]
      end

    {:noreply, assign(socket, :selected_years_ids, selected_years_ids)}
  end

  def handle_event("validate", %{"curriculum_item" => curriculum_item_params}, socket) do
    changeset =
      socket.assigns.curriculum_item
      |> Curricula.change_curriculum_item(curriculum_item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"curriculum_item" => curriculum_item_params}, socket) do
    curriculum_item_params =
      case socket.assigns.is_admin do
        true ->
          curriculum_item_params

        false ->
          curriculum_item_params
          |> Map.put("id", socket.assigns.curriculum_item.id)
          |> Map.put(
            "curriculum_component_id",
            socket.assigns.curriculum_item.curriculum_component_id
          )
          |> Map.put(
            "subjects_ids",
            socket.assigns.selected_subjects_ids
          )
          |> Map.put(
            "years_ids",
            socket.assigns.selected_years_ids
          )
      end

    save_curriculum_item(socket, socket.assigns.curriculum_item.id, curriculum_item_params)
  end

  defp save_curriculum_item(socket, nil, curriculum_item_params) do
    case Curricula.create_curriculum_item(curriculum_item_params) do
      {:ok, curriculum_item} ->
        notify_parent(__MODULE__, {:saved, curriculum_item}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Curriculum item created successfully")
          |> handle_navigation(curriculum_item)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_curriculum_item(socket, _curriculum_item_id, curriculum_item_params) do
    case Curricula.update_curriculum_item(socket.assigns.curriculum_item, curriculum_item_params) do
      {:ok, curriculum_item} ->
        notify_parent(__MODULE__, {:saved, curriculum_item}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Curriculum item updated successfully")
          |> handle_navigation(curriculum_item)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
