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
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Scale name")}
          class="mb-6"
          phx-debounce="500"
        />
        <div :if={@scale.type == "numeric"} class="mb-6">
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
          <.card_base class="flex items-center gap-2 p-6 mb-6">
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
        <div :if={@scale.type == "ordinal"} class="mb-6">
          <.input
            field={@form[:breakpoints_input]}
            type="text"
            label={gettext("Breakpoints")}
            placeholder="e.g. 0.1, 0.3, 0.7"
            class="mb-6"
            phx-debounce="500"
          />
        </div>
        <.error_block
          :if={@delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{@delete_error}</p>
        </.error_block>
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
      |> assign(:delete_error, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{scale: scale} = assigns, socket) do
    changeset = Grading.change_scale(assigns.current_scope, scale)

    changeset =
      Ecto.Changeset.put_change(
        changeset,
        :breakpoints_input,
        format_breakpoints(scale.breakpoints)
      )

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

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

        {:error, changeset} ->
          delete_error =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
            |> Enum.map_join(" ", fn {_field, msg} -> msg end)

          assign(socket, :delete_error, delete_error)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :delete_error, nil)}

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

  defp format_breakpoints(nil), do: ""
  defp format_breakpoints(breakpoints), do: Enum.join(breakpoints, ", ")

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
