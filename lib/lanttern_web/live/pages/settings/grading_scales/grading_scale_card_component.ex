defmodule LantternWeb.GradingScalesLive.GradingScaleCardComponent do
  @moduledoc """
  Card component for displaying and managing a grading scale.
  """

  use LantternWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <.card_base class="overflow-hidden">
        <%!-- Header --%>
        <div class="flex items-center gap-4 p-6">
          <div class="flex-1 flex items-center gap-4 relative min-w-0">
            <button
              type="button"
              phx-click="toggle"
              phx-target={@myself}
              class={[
                "shrink-0 font-bold text-left hover:text-ltrn-subtle truncate text-base",
                if(@disabled, do: "text-ltrn-subtle")
              ]}
            >
              {@scale.name}
            </button>
            <div class="overflow-hidden">
              <%!-- Ordinal value color badges --%>
              <div :if={@scale.type == "ordinal"} class="flex gap-2">
                <.badge
                  :for={ov <- @scale.ordinal_values}
                  color_map={ov}
                  rounded
                >
                  {String.slice(ov.name, 0, 2)}
                </.badge>
              </div>
            </div>
            <div class="absolute inset-y-0 right-0 w-20 bg-linear-to-l from-white to-white/0" />
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
        <%= if @is_expanded do %>
          <div class="border-t border-ltrn-lighter">
            <%!-- Ordinal values table --%>
            <div :if={@scale.type == "ordinal"} class="p-6">
              <div class="grid grid-cols-3 gap-4 mb-2 text-sm font-semibold text-ltrn-subtle">
                <span>{gettext("Ordinal values")}</span>
                <span class="text-center">{gettext("Normalized value")}</span>
                <span></span>
              </div>
              <div>
                <div
                  :for={ov <- @scale.ordinal_values}
                  class="grid grid-cols-3 gap-4 py-3 border-t border-ltrn-lighter items-center"
                >
                  <.badge
                    color_map={ov}
                    rounded
                    class="px-2 py-1 w-fit"
                  >
                    {ov.name}
                  </.badge>
                  <span class="font-mono text-center">{ov.normalized_value}</span>
                  <div class="flex justify-end">
                    <.action_icon
                      type="button"
                      name="hero-pencil-mini"
                      sr_text={gettext("Edit ordinal value")}
                      theme="subtle"
                      phx-click="edit_ordinal_value"
                      phx-value-id={ov.id}
                      phx-target={@myself}
                    />
                  </div>
                </div>
              </div>
              <%!-- Add value button --%>
              <button
                type="button"
                phx-click="new_ordinal_value"
                phx-target={@myself}
                class="mt-4
                flex items-center gap-2 text-sm border-2 border-dashed border-ltrn-lighter rounded-full px-2 py-1 hover:border-ltrn-subtle transition-colors"
              >
                {gettext("Add value")}
                <.icon name="hero-plus-mini" class="w-4 h-4" />
              </button>
            </div>
            <%!-- Numeric scale details --%>
            <div :if={@scale.type == "numeric"} class="flex gap-8 p-6 text-sm">
              <div>
                <span class="text-ltrn-subtle">{gettext("Start")}: </span>
                <span class="font-mono font-bold">{@scale.start}</span>
              </div>
              <div>
                <span class="text-ltrn-subtle">{gettext("Stop")}: </span>
                <span class="font-mono font-bold">{@scale.stop}</span>
              </div>
            </div>
            <%!-- Breakpoints --%>
            <div
              :if={@scale.breakpoints && @scale.breakpoints != []}
              class="border-t border-ltrn-lighter px-6 py-4"
            >
              <h6 class="text-sm font-semibold text-ltrn-subtle mb-1">{gettext("Breakpoints")}</h6>
              <p class="font-mono">{Enum.join(@scale.breakpoints, ", ")}</p>
            </div>
          </div>
        <% end %>
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
