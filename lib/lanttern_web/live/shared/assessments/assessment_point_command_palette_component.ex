defmodule LantternWeb.Assessments.AssessmentPointCommandPaletteComponent do
  @moduledoc """
  Command palette modal for assessment point management.

  Shows 3 sections: edit, grade composition, and student visibility.
  Notifies the parent component on all actions.

  ### Required attrs

  - `:ap` - `AssessmentPoint` (needs `composition_type` and `is_hidden`)
  - `:on_cancel` - JS action to close the palette
  - `:notify_component` - parent LiveComponent CID (`@myself`)
  """
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show on_cancel={@on_cancel}>
        <:title>{@ap.name || @ap.curriculum_item.name}</:title>
        <div class="-mx-10">
          <div class="px-10 pb-10">
            <.button type="button" phx-click="edit" phx-target={@myself}>
              {gettext("Edit assessment point")}
            </.button>
          </div>
          <div class="border-t border-ltrn-light p-10">
            <%= if is_nil(@ap.composition_type) do %>
              <div class="flex flex-wrap gap-2">
                <.button
                  type="button"
                  phx-click="add_composition"
                  phx-value-type="sum"
                  phx-target={@myself}
                >
                  {gettext("Add sum-based composition")}
                </.button>
                <.button
                  type="button"
                  phx-click="add_composition"
                  phx-value-type="avg"
                  phx-target={@myself}
                >
                  {gettext("Add average-based composition")}
                </.button>
              </div>
              <p class="mt-4">
                {gettext(
                  "Use grade composition to calculate entries based on sum or average of other assessment points."
                )}
              </p>
            <% else %>
              <.button
                type="button"
                theme="primary"
                icon_name="hero-calculator-micro"
                phx-click="manage_composition"
                phx-target={@myself}
              >
                {gettext("Manage grade composition")}
              </.button>
              <p class="mt-4">
                <%= if @ap.composition_type == :sum do %>
                  {gettext("This assessment point uses a sum-based grade composition.")}
                <% else %>
                  {gettext("This assessment point uses an average-based grade composition.")}
                <% end %>
              </p>
            <% end %>
          </div>
          <div class="border-t border-ltrn-light px-10 pt-10">
            <%= if @ap.is_hidden do %>
              <.button
                type="button"
                theme="primary"
                icon_name="hero-eye-slash-micro"
                phx-click="toggle_hidden"
                phx-target={@myself}
              >
                {gettext("Hidden from students")}
              </.button>
              <p class="mt-4">
                {gettext("Students won't see marking results for this assessment point.")}
              </p>
            <% else %>
              <.button type="button" phx-click="toggle_hidden" phx-target={@myself}>
                {gettext("Hide from students")}
              </.button>
              <p class="mt-4">
                {gettext(
                  "When hidden, students won't see marking results for this assessment point. Use this while marking is in progress."
                )}
              </p>
            <% end %>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("edit", _, socket) do
    notify(__MODULE__, {:edit}, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("add_composition", %{"type" => type}, socket) do
    notify(__MODULE__, {:add_composition, type}, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("manage_composition", _, socket) do
    notify(__MODULE__, {:manage_composition}, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("toggle_hidden", _, socket) do
    notify(__MODULE__, {:toggle_hidden}, socket.assigns)
    {:noreply, socket}
  end
end
