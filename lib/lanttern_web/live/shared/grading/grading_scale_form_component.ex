defmodule LantternWeb.Grading.GradingScaleFormComponent do
  @moduledoc """
  Form component for creating and editing grading scales.
  """

  use LantternWeb, :live_component

  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <%!-- <.error :if={@changeset.action}>
          Oops, something went wrong! Please check the errors below.
        </.error> --%>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Scale name")}
          class="mb-6"
          phx-debounce="500"
        />
        <div :if={@scale.type == "numeric"}>
          <div class="flex items-start gap-4 mb-6">
            <.input
              field={@form[:start]}
              type="number"
              label="Start"
              step="1"
              class="flex-1 shrink-0"
            />
            <.input
              field={@form[:start_bg_color]}
              type="color"
              label="Start background color"
              class="flex-1 shrink-0"
            />
            <.input
              field={@form[:start_text_color]}
              type="color"
              label="Start text color"
              class="flex-1 shrink-0"
            />
          </div>
          <div class="flex items-start gap-4 mb-6">
            <.input
              field={@form[:stop]}
              type="number"
              label="Stop"
              step="any"
              class="flex-1 shrink-0"
            />
            <.input
              field={@form[:stop_bg_color]}
              type="color"
              label="Stop background color"
              class="flex-1 shrink-0"
            />
            <.input
              field={@form[:stop_text_color]}
              type="color"
              label="Stop text color"
              class="flex-1 shrink-0"
            />
          </div>
          <.card_base class="flex items-center gap-2 p-6">
            <p class="text-ltrn-subtle">{gettext("Preview")}</p>
            <.badge color_map={
              %{bg_color: @form[:start_bg_color].value, text_color: @form[:start_text_color].value}
            }>
              {@form[:start].value}
            </.badge>
            <.badge color_map={
              %{bg_color: @form[:stop_bg_color].value, text_color: @form[:stop_text_color].value}
            }>
              {@form[:stop].value}
            </.badge>
          </.card_base>
        </div>
        <div :if={@scale.type == "ordinal"}>
          <div phx-feedback-for="scale[breakpoints]">
            <.label>Breakpoints</.label>
            <%= for n <- 0..4 do %>
              <input
                type="number"
                step="0.01"
                max="1"
                name="scale[breakpoints][]"
                value={Enum.at(@form[:breakpoints].value || [], n)}
                class={[
                  "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
                  "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400"
                ]}
              />
            <% end %>
            <.error :for={
              msg <-
                Enum.map(@form[:breakpoints].errors, fn {msg, opts} ->
                  Gettext.dgettext(Lanttern.Gettext, "errors", msg, opts)
                end)
            }>
              {msg}
            </.error>
          </div>
        </div>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@scale.id}
              type="button"
              theme="ghost"
              phx-click="delete"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
            >
              {gettext("Delete")}
            </.button>
          </div>
          <div class="flex gap-2">
            <.button
              type="button"
              theme="ghost"
              phx-click={@on_cancel}
            >
              {gettext("Cancel")}
            </.button>
            <.button type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:has_delete_error, false)

    {:ok, socket}
  end

  @impl true
  def update(%{scale: scale} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(Grading.change_scale(assigns.current_scope, scale))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"scale" => scale_params}, socket) do
    changeset =
      Grading.change_scale(
        socket.assigns.current_scope,
        socket.assigns.scale,
        scale_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Grading.delete_scale(
             socket.assigns.current_scope,
             socket.assigns.scale
           ) do
        {:ok, scale} ->
          message = {:deleted, scale}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Scale deleted"))
          |> handle_navigation(message)

        {:error, _changeset} ->
          assign(socket, :has_delete_error, true)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :has_delete_error, false)}

  def handle_event("save", %{"scale" => scale_params}, socket) do
    save_scale(socket, socket.assigns.scale.id, scale_params)
  end

  defp save_scale(socket, nil, scale_params) do
    # extract scale type from scale assign
    scale_params = Map.put(scale_params, "type", socket.assigns.scale.type)

    case Grading.create_scale(
           socket.assigns.current_scope,
           scale_params
         ) do
      {:ok, scale} ->
        message = {:created, scale}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Scale created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_scale(socket, _id, scale_params) do
    case Grading.update_scale(
           socket.assigns.current_scope,
           socket.assigns.scale,
           scale_params
         ) do
      {:ok, scale} ->
        message = {:updated, scale}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Scale updated"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
