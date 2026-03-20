defmodule LantternWeb.GradingScalesLive.GradingScaleCardComponent do
  @moduledoc """
  Card component for displaying and managing a grading scale.
  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <.card_base class="overflow-hidden">
        <%!-- Header --%>
        <div class="flex items-center gap-4 p-6">
          <.drag_handle :if={!@disabled} class="sortable-handle" />
          <div class="flex-1 flex items-center gap-4 relative min-w-0">
            <button
              type="button"
              phx-click="toggle"
              phx-target={@myself}
              class={[
                "shrink-0 font-bold text-left hover:text-ltrn-subtle truncate",
                if(@disabled, do: "text-ltrn-subtle")
              ]}
            >
              {@scale.name}
            </button>
            <%!-- Ordinal value color badges --%>
            <div :if={@scale.type == "ordinal"} class="overflow-hidden">
              <div class="flex gap-2">
                <.badge
                  :for={ov <- @scale.ordinal_values}
                  color_map={ov}
                >
                  {ov.short_name || String.slice(ov.name, 0, 2)}
                </.badge>
              </div>
            </div>
            <%!-- Overlay for extreme long list of ordinal values --%>
            <div class="absolute inset-y-0 right-0 w-20 bg-linear-to-l from-white to-white/0" />
            <%!-- Ordinal value color badges --%>
            <div :if={@scale.type == "numeric"} class="flex items-center gap-2">
              <.badge color_map={
                %{bg_color: @scale.start_bg_color, text_color: @scale.start_text_color}
              }>
                {@scale.start}
              </.badge>
              —
              <.badge color_map={
                %{bg_color: @scale.stop_bg_color, text_color: @scale.stop_text_color}
              }>
                {@scale.stop}
              </.badge>
            </div>
          </div>
          <div class="shrink-0 flex items-center gap-2">
            <div>
              <.toggle
                enabled={!@disabled}
                phx-click={if(@disabled, do: "activate_scale", else: "deactivate_scale")}
                phx-target={@myself}
                data-confirm={gettext("Are you sure?")}
              />
              <.tooltip id={"toggle-scale-activate-#{@id}"}>
                {if @disabled, do: gettext("Reactivate scale"), else: gettext("Deactivate scale")}
              </.tooltip>
            </div>
            <%!-- Edit scale button --%>
            <.icon_button
              name="hero-pencil-mini"
              sr_text={gettext("Edit scale")}
              theme="ghost"
              phx-click="edit_scale"
              phx-target={@myself}
            />
            <%!-- Toggle chevron --%>
            <.icon_button
              name={if @is_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
              sr_text={gettext("Toggle scale card")}
              theme="ghost"
              phx-click="toggle"
              phx-target={@myself}
            />
          </div>
        </div>
        <%!-- Expanded content --%>
        <div :if={@is_expanded} class="border-t border-ltrn-lighter p-6">
          <%!-- Ordinal values table --%>
          <div :if={@scale.type == "ordinal"}>
            <div class="grid grid-cols-[1fr_1fr_min-content] gap-x-6 gap-y-4 items-center">
              <div class="col-span-3 grid grid-cols-subgrid items-center">
                <span class="font-sans text-sm">{gettext("Ordinal values")}</span>
                <span class="font-sans text-sm">{gettext("Normalized value")}</span>
                <span></span>
              </div>
              <div
                :for={ov <- @scale.ordinal_values}
                class="col-span-3 grid grid-cols-subgrid items-center"
              >
                <div>
                  <.badge color_map={ov}>
                    {ov.name}
                  </.badge>
                </div>
                <span class="font-bold">{ov.normalized_value}</span>
                <.icon_button
                  name="hero-pencil-mini"
                  theme="ghost"
                  sr_text={gettext("Edit ordinal value")}
                  phx-click="edit_ordinal_value"
                  phx-value-id={ov.id}
                  phx-target={@myself}
                />
              </div>
            </div>
            <%!-- Add value button --%>
            <.button
              type="button"
              icon_name="hero-plus-mini"
              size="sm"
              phx-click="new_ordinal_value"
              phx-target={@myself}
              class="mt-4"
            >
              {gettext("Add value")}
            </.button>
            <%!-- Breakpoints --%>
            <div
              :if={@scale.breakpoints && @scale.breakpoints != []}
              class="border-t border-ltrn-lighter pt-4 mt-4"
            >
              <h6 class="text-sm font-sans mb-2">{gettext("Breakpoints")}</h6>
              <p class="font-bold">{Enum.join(@scale.breakpoints, ", ")}</p>
            </div>
          </div>
          <%!-- Numeric scale details --%>
          <p :if={@scale.type == "numeric"}>
            {gettext("Numeric scale, from %{start} to %{stop}",
              start: @scale.start,
              stop: @scale.stop
            )}
          </p>
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
  def update(assigns, %{assigns: %{scale: _scale}} = socket) do
    is_expanded = assigns.selected_scale_id == "#{socket.assigns.scale.id}"

    socket =
      socket
      |> assign(:is_expanded, is_expanded)
      |> then(fn s ->
        if Map.has_key?(assigns, :scale), do: assign(s, :scale, assigns.scale), else: s
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
        do: ~p"/settings/grading_scales",
        else: ~p"/settings/grading_scales/#{socket.assigns.scale.id}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("edit_scale", _params, socket) do
    send(self(), {__MODULE__, {:edit_scale, socket.assigns.scale.id}})
    {:noreply, socket}
  end

  def handle_event("edit_ordinal_value", %{"id" => id}, socket) do
    send(self(), {__MODULE__, {:edit_ordinal_value, id}})
    {:noreply, socket}
  end

  def handle_event("new_ordinal_value", _params, socket) do
    send(self(), {__MODULE__, {:new_ordinal_value, socket.assigns.scale.id}})
    {:noreply, socket}
  end

  def handle_event("activate_scale", _params, socket) do
    send(self(), {__MODULE__, {:activate_scale, socket.assigns.scale.id}})
    {:noreply, socket}
  end

  def handle_event("deactivate_scale", _params, socket) do
    send(self(), {__MODULE__, {:deactivate_scale, socket.assigns.scale.id}})
    {:noreply, socket}
  end
end
