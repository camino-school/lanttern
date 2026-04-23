defmodule LantternWeb.CurriculaSettingsLive.CurriculumCardComponent do
  @moduledoc """
  Card component for displaying and managing a curriculum.
  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <.card_base class="overflow-hidden">
        <%!-- Header --%>
        <div class="flex items-center gap-4 p-6">
          <div class="flex-1 min-w-0">
            <button
              type="button"
              phx-click="toggle"
              phx-target={@myself}
              class={[
                "font-bold text-left hover:text-ltrn-subtle truncate",
                if(@disabled, do: "text-ltrn-subtle")
              ]}
            >
              {@curriculum.name}
            </button>
          </div>
          <div class="shrink-0 flex items-center gap-2">
            <div>
              <.toggle
                enabled={!@disabled}
                phx-click={if(@disabled, do: "activate_curriculum", else: "deactivate_curriculum")}
                phx-target={@myself}
                data-confirm={gettext("Are you sure?")}
              />
              <.tooltip id={"toggle-curriculum-activate-#{@id}"}>
                {if @disabled,
                  do: gettext("Reactivate curriculum"),
                  else: gettext("Deactivate curriculum")}
              </.tooltip>
            </div>
            <.icon_button
              name="hero-pencil-mini"
              sr_text={gettext("Edit curriculum")}
              theme="ghost"
              phx-click="edit_curriculum"
              phx-target={@myself}
            />
            <.icon_button
              name={if @is_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
              sr_text={gettext("Toggle curriculum card")}
              theme="ghost"
              phx-click="toggle"
              phx-target={@myself}
            />
          </div>
        </div>
        <%!-- Expanded content --%>
        <div :if={@is_expanded} class="border-t border-ltrn-lighter p-6">
          <div :if={@curriculum.curriculum_components != []}>
            <div class="grid grid-cols-[min-content_1fr_auto_min-content] gap-x-4 gap-y-4 items-center">
              <div class="col-span-4 grid grid-cols-subgrid items-center">
                <span></span>
                <span class="font-sans text-sm">{gettext("Components")}</span>
                <span class="font-sans text-sm">{gettext("Code")}</span>
                <span></span>
              </div>
              <div
                phx-hook="Sortable"
                id={"curriculum-#{@curriculum.id}-components-sortable"}
                data-sortable-handle=".sortable-handle"
                data-sortable-event="sortable_update"
                class="col-span-4 grid grid-cols-subgrid gap-y-4"
              >
                <div
                  :for={cc <- @curriculum.curriculum_components}
                  id={"curriculum-component-#{cc.id}"}
                  class="col-span-4 grid grid-cols-subgrid items-center"
                >
                  <.drag_handle class="sortable-handle" />
                  <span>{cc.name}</span>
                  <div>
                    <%= if cc.code && cc.code != "" do %>
                      <.badge color_map={cc}>{cc.code}</.badge>
                    <% else %>
                      <span class="text-ltrn-subtle">—</span>
                    <% end %>
                  </div>
                  <.icon_button
                    name="hero-pencil-mini"
                    theme="ghost"
                    sr_text={gettext("Edit component")}
                    phx-click="edit_curriculum_component"
                    phx-value-id={cc.id}
                    phx-target={@myself}
                  />
                </div>
              </div>
            </div>
          </div>
          <p :if={@curriculum.curriculum_components == []} class="text-ltrn-subtle">
            {gettext("No components yet")}
          </p>
          <.button
            type="button"
            icon_name="hero-plus-mini"
            size="sm"
            phx-click="new_curriculum_component"
            phx-target={@myself}
            class="mt-4"
          >
            {gettext("Add component")}
          </.button>
        </div>
      </.card_base>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  # subsequent updates — via send_update (accordion toggle) or parent re-render (data update)
  def update(assigns, %{assigns: %{curriculum: _curriculum}} = socket) do
    is_expanded = assigns.selected_curriculum_id == "#{socket.assigns.curriculum.id}"

    socket =
      socket
      |> assign(:is_expanded, is_expanded)
      |> then(fn s ->
        if Map.has_key?(assigns, :curriculum),
          do: assign(s, :curriculum, assigns.curriculum),
          else: s
      end)
      |> then(fn s ->
        if Map.has_key?(assigns, :disabled), do: assign(s, :disabled, assigns.disabled), else: s
      end)

    {:ok, socket}
  end

  def update(assigns, socket) do
    disabled = Map.get(assigns, :disabled, false)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:is_expanded, false)
     |> assign(:disabled, disabled)}
  end

  # event handlers

  @impl true
  def handle_event("toggle", _params, socket) do
    path =
      if socket.assigns.is_expanded,
        do: ~p"/settings/curricula",
        else: ~p"/settings/curricula/#{socket.assigns.curriculum.id}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("edit_curriculum", _params, socket) do
    send(self(), {__MODULE__, {:edit_curriculum, socket.assigns.curriculum.id}})
    {:noreply, socket}
  end

  def handle_event("edit_curriculum_component", %{"id" => id}, socket) do
    send(self(), {__MODULE__, {:edit_curriculum_component, id}})
    {:noreply, socket}
  end

  def handle_event("new_curriculum_component", _params, socket) do
    send(self(), {__MODULE__, {:new_curriculum_component, socket.assigns.curriculum.id}})
    {:noreply, socket}
  end

  def handle_event(
        "sortable_update",
        %{"oldIndex" => old_index, "newIndex" => new_index},
        socket
      )
      when old_index != new_index do
    components = socket.assigns.curriculum.curriculum_components
    {moved, rest} = List.pop_at(components, old_index)
    reordered = List.insert_at(rest, new_index, moved)
    ids = Enum.map(reordered, & &1.id)

    send(self(), {__MODULE__, {:reorder_curriculum_components, ids}})
    {:noreply, socket}
  end

  def handle_event("sortable_update", _, socket), do: {:noreply, socket}

  def handle_event("activate_curriculum", _params, socket) do
    send(self(), {__MODULE__, {:activate_curriculum, socket.assigns.curriculum.id}})
    {:noreply, socket}
  end

  def handle_event("deactivate_curriculum", _params, socket) do
    send(self(), {__MODULE__, {:deactivate_curriculum, socket.assigns.curriculum.id}})
    {:noreply, socket}
  end
end
