defmodule LantternWeb.LearningContext.StrandClassAssignmentOverlayComponent do
  @moduledoc """
  Renders a modal overlay for assigning classes to a strand.

  Expected external assigns:

  ```elixir
  attr :current_user, Lanttern.Identity.User, required: true
  attr :current_scope, Lanttern.Identity.Scope, required: true
  attr :strand, Lanttern.LearningContext.Strand, required: true, doc: "must have :years preloaded"
  attr :classes, :list, required: true, doc: "available classes for this strand's years/cycle"
  attr :assigned_classes_ids, :list, required: true, doc: "IDs of currently assigned classes"
  attr :navigate, :string, required: true, doc: "path to navigate to after applying"
  ```
  """

  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers, only: [handle_filter_toggle: 3]

  alias Lanttern.Strands
  alias LantternWeb.Schools.ClassSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id}>
        <h5 class="mb-6 font-display font-black text-xl">
          {gettext("Assign classes to this strand")}
        </h5>
        <.badge_button_picker
          on_select={
            &JS.push("toggle_class",
              value: %{"id" => &1},
              target: @myself
            )
          }
          items={@core_classes}
          selected_ids={@selected_classes_ids}
          label_setter="class_with_cycle"
          current_user={@current_user}
        />
        <div :if={@extra_classes != []} class="mt-4">
          <p class="mb-2 text-sm font-semibold text-ltrn-subtle">{gettext("Extra classes")}</p>
          <.badge_button_picker
            on_select={
              &JS.push("toggle_class",
                value: %{"id" => &1},
                target: @myself
              )
            }
            items={@extra_classes}
            selected_ids={@selected_classes_ids}
            label_setter="class_with_cycle"
            current_user={@current_user}
          />
        </div>
        <form class="mt-6">
          <.live_component
            module={ClassSearchComponent}
            id={"#{@id}-class-search"}
            notify_component={@myself}
            school_id={@current_user.current_profile.school_id}
            label={gettext("Search all school classes")}
          />
        </form>
        <div class="flex justify-between gap-2 mt-10">
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.push("clear_assignments", target: @myself)}
          >
            {gettext("Clear")}
          </.button>
          <div class="flex gap-2">
            <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
              {gettext("Cancel")}
            </.button>
            <.button
              type="button"
              disabled={!@has_changes}
              phx-click={JS.push("apply_assignments", target: @myself)}
              phx-disable-with={gettext("Saving...")}
            >
              {gettext("Assign classes")}
            </.button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :has_changes, false)}
  end

  @impl true
  def update(%{action: {ClassSearchComponent, {:selected, class}}}, socket) do
    selected_classes_ids =
      [class.id | socket.assigns.selected_classes_ids]
      |> Enum.uniq()

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> maybe_add_class_from_search(class)
      |> assign(:has_changes, true)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_classes_ids, fn -> assigns.assigned_classes_ids end)
      |> assign_classes_groups()

    {:ok, socket}
  end

  defp assign_classes_groups(socket) do
    {core, extra} = Enum.split_with(socket.assigns.classes, & &1.is_core)

    socket
    |> assign(:core_classes, core)
    |> assign(:extra_classes, extra)
  end

  defp maybe_add_class_from_search(socket, class) do
    classes_ids = Enum.map(socket.assigns.classes, & &1.id)

    if class.id in classes_ids do
      socket
    else
      socket
      |> assign(:classes, socket.assigns.classes ++ [class])
      |> assign_classes_groups()
    end
  end

  # event handlers

  @impl true
  def handle_event("toggle_class", %{"id" => id}, socket) do
    socket =
      socket
      |> handle_filter_toggle(:classes, id)
      |> assign(:has_changes, true)

    {:noreply, socket}
  end

  def handle_event("clear_assignments", _, socket) do
    socket =
      socket
      |> assign(:selected_classes_ids, [])
      |> assign(:has_changes, true)

    {:noreply, socket}
  end

  def handle_event("apply_assignments", _, socket) do
    case Strands.sync_strand_class_assignments(
           socket.assigns.current_scope,
           socket.assigns.strand.id,
           socket.assigns.selected_classes_ids
         ) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, gettext("Strand classes updated"))
          |> push_navigate(to: socket.assigns.navigate)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update class assignments"))}
    end
  end
end
