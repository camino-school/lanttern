defmodule LantternWeb.GradingScalesLive.GradingScaleCardComponent do
  @moduledoc """
  Card component for displaying and managing a grading scale.
  """

  use LantternWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={@id} class={["mt-4 first:mt-0", @disabled && "opacity-50"]}>
      <.card_base class="overflow-hidden">
        <%!-- Header --%>
        <div class="flex justify-between gap-4 p-6">
          <div class="flex gap-4 min-w-0">
            <button
              type="button"
              phx-click={unless @disabled, do: "toggle"}
              phx-target={@myself}
              class="font-bold text-left hover:text-ltrn-subtle truncate text-base"
            >
              {@scale.name}
            </button>
            <div>
              <%!-- Ordinal value color badges --%>
              <div :if={@scale.type == "ordinal"} class="flex gap-1">
                <.badge
                  :for={ov <- Enum.take(@scale.ordinal_values, 10)}
                  color_map={ov}
                  rounded
                  class="w-8 h-8 !px-0 justify-center text-xs font-bold shrink-0"
                >
                  {String.slice(ov.name, 0, 2)}
                </.badge>
              </div>
            </div>
            <div
              :if={length(@scale.ordinal_values) > 10}
              class="flex items-center justify-center w-8 h-8 text-xs font-bold"
            >
              ...
            </div>
          </div>
          <div>
            <%= if @disabled do %>
              <%!-- Re-enable button --%>
              <.button
                type="button"
                theme="secondary"
                phx-click="re_enable_scale"
                phx-target={@myself}
              >
                {gettext("Re-enable")}
              </.button>
            <% else %>
              <%!-- Delete scale button --%>
              <.icon_button
                name="hero-minus-circle-solid"
                sr_text={gettext("Delete scale")}
                theme="ghost"
                class="!text-ltrn-alert-accent hover:!bg-ltrn-alert-lighter"
                phx-click="delete_scale"
                phx-target={@myself}
                data-confirm={gettext("Are you sure?")}
              />
              <%!-- Edit scale button --%>
              <.icon_button
                name="hero-pencil-solid"
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
            <% end %>
          </div>
        </div>
        <%!-- Expanded content --%>
        <%= if @is_expanded && !@disabled do %>
          <div class="border-t border-ltrn-lighter">
            <%!-- Ordinal values table --%>
            <div :if={@scale.type == "ordinal"} class="p-6">
              <div class="flex justify-between mb-2 text-sm font-semibold text-ltrn-subtle">
                <span>{gettext("Ordinal values")}</span>
                <span>{gettext("Normalized value")}</span>
              </div>
              <div>
                <div
                  :for={ov <- @scale.ordinal_values}
                  class="flex items-center gap-4 py-3 border-t border-ltrn-lighter"
                >
                  <.badge
                    color_map={ov}
                    rounded
                    class="inline-flex flex-col items-center justify-center gap-2.5 px-2 py-1 row-start-2 col-start-1"
                  >
                    {ov.name}
                  </.badge>
                  <span class="flex-1 font-mono text-right">{ov.normalized_value}</span>
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
              <%!-- Add value button --%>
              <button
                type="button"
                phx-click="new_ordinal_value"
                phx-target={@myself}
                class="mt-4
                flex items-center gap-2 text-sm border-2 border-dashed border-ltrn-lighter rounded-full px-4 py-2 hover:border-ltrn-subtle transition-colors"
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

  def handle_event("delete_scale", _params, socket) do
    send(self(), {__MODULE__, {:delete_scale, socket.assigns.scale.id}})
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

  def handle_event("re_enable_scale", _params, socket) do
    send(self(), {__MODULE__, {:re_enable_scale, socket.assigns.scale.id}})
    {:noreply, socket}
  end
end
