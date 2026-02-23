defmodule LantternWeb.Schools.GuardiansFieldComponent do
  @moduledoc """
  Renders a guardians picker to use in forms.

  This component displays a searchable list of guardians with selection capability.

  ### Attrs

      attr :label, :string, required: true
      attr :selected_guardians_ids, :list, required: true, doc: "the selected guardians ids list"
      attr :guardians, :list, required: true, doc: "list of available guardians"
      attr :form_id, :string, required: true, doc: "the form id to dispatch change events to"
      attr :notify_component, Phoenix.LiveComponent.CID
      attr :class, :any

  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center justify-between mb-2">
        <.label>{@label}</.label>
        <button
          type="button"
          phx-click={show_modal("guardians-picker-modal-#{@id}")}
          class="text-sm text-ltrn-primary hover:text-ltrn-primary-dark"
        >
          {gettext("Add guardian")}
        </button>
      </div>

      <%= if @selected_guardians != [] do %>
        <.badge_button_picker
          id="selected-guardians-picker-#{@id}"
          on_select={
            &(JS.push("unselect_guardian", value: %{"id" => &1}, target: @myself)
              |> JS.dispatch("change", to: "##{@form_id}"))
          }
          items={@selected_guardians}
          selected_ids={@selected_guardians_ids}
        />
      <% else %>
        <.empty_state_simple>{gettext("No guardians selected")}</.empty_state_simple>
      <% end %>

      <.modal id={"guardians-picker-modal-#{@id}"} on_cancel={hide_modal("guardians-picker-modal-#{@id}")}>
        <div class="p-6">
          <h2 class="text-lg font-semibold mb-4">{gettext("Select guardians")}</h2>
          <.input
            type="search"
            name="guardians_search"
            value={@search_term}
            placeholder={gettext("Search guardian...")}
            phx-keyup="search_guardians"
            phx-debounce="300"
            phx-target={@myself}
            autocomplete="off"
          />
          <div class="mt-6 space-y-2 max-h-96 overflow-y-auto">
            <%= if @search_results != [] do %>
              <%= for guardian <- @search_results do %>
                <div class="flex items-center justify-between p-3 border border-ltrn-lighter rounded hover:bg-ltrn-mesh-light cursor-pointer">
                  <span class="font-medium">{guardian.name}</span>
                  <button
                    type="button"
                    phx-click={JS.push("toggle_guardian", value: %{"id" => guardian.id}, target: @myself)}
                    class={
                      if guardian.id in @selected_guardians_ids,
                        do: "text-ltrn-primary font-semibold",
                        else: "text-ltrn-subtle hover:text-ltrn-dark"
                    }
                  >
                    <%= if guardian.id in @selected_guardians_ids do %>
                      <.icon name="hero-check" class="h-5 w-5" />
                    <% else %>
                      <.icon name="hero-plus" class="h-5 w-5" />
                    <% end %>
                  </button>
                </div>
              <% end %>
            <% else %>
              <.empty_state_simple>{gettext("No guardians found")}</.empty_state_simple>
            <% end %>
          </div>
          <div class="mt-6 flex justify-end gap-2">
            <.action
              type="button"
              theme="ghost"
              phx-click={hide_modal("guardians-picker-modal-#{@id}")}
            >
              {gettext("Close")}
            </.action>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:search_term, "")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_selected_guardians()
      |> assign_search_results()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    assign(socket, :initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_selected_guardians(socket) do
    selected_guardians_ids = socket.assigns.selected_guardians_ids
    guardians = socket.assigns.guardians

    selected_guardians =
      Enum.filter(guardians, fn guardian -> guardian.id in selected_guardians_ids end)

    assign(socket, :selected_guardians, selected_guardians)
  end

  defp assign_search_results(socket) do
    search_term = socket.assigns.search_term
    guardians = socket.assigns.guardians

    search_results =
      if String.trim(search_term) == "" do
        guardians
      else
        lower_search = String.downcase(search_term)

        Enum.filter(guardians, fn guardian ->
          String.contains?(String.downcase(guardian.name), lower_search)
        end)
      end

    assign(socket, :search_results, search_results)
  end

  @impl true
  def handle_event("search_guardians", %{"value" => search_term}, socket) do
    {:noreply, assign(socket, :search_term, search_term) |> assign_search_results()}
  end

  def handle_event("toggle_guardian", %{"id" => guardian_id}, socket) do
    guardian_id = if is_binary(guardian_id), do: String.to_integer(guardian_id), else: guardian_id

    selected_guardians_ids =
      if guardian_id in socket.assigns.selected_guardians_ids,
        do: Enum.filter(socket.assigns.selected_guardians_ids, fn id -> id != guardian_id end),
        else: [guardian_id | socket.assigns.selected_guardians_ids]

    notify_change(socket, selected_guardians_ids)
  end

  def handle_event("unselect_guardian", %{"id" => guardian_id}, socket) do
    guardian_id = if is_binary(guardian_id), do: String.to_integer(guardian_id), else: guardian_id

    selected_guardians_ids =
      Enum.filter(socket.assigns.selected_guardians_ids, fn id -> id != guardian_id end)

    notify_change(socket, selected_guardians_ids)
  end

  defp notify_change(socket, selected_guardians_ids) do
    socket =
      socket
      |> assign(:selected_guardians_ids, selected_guardians_ids)
      |> assign_selected_guardians()

    send_update(socket.assigns.notify_component, action: {__MODULE__, {:changed, selected_guardians_ids}})

    {:noreply, socket}
  end
end
