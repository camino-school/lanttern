defmodule LantternWeb.GradingScalesLive.OrdinalValueFormComponent do
  @moduledoc """
  Form component for creating and editing ordinal values within a grading scale.
  """

  use LantternWeb, :live_component

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <div class="flex items-start gap-4 mb-6">
          <.input field={@form[:name]} type="text" label={gettext("Name")} class="flex-2" />
          <.input field={@form[:short_name]} type="text" label={gettext("Short name")} class="flex-1" />
          <.input
            field={@form[:normalized_value]}
            type="number"
            label={gettext("Normalized value")}
            step="0.01"
            min="0"
            max="1"
            class="flex-1"
          />
        </div>
        <.input field={@form[:scale_id]} type="hidden" />
        <div class="flex gap-4 mb-6">
          <.input
            field={@form[:bg_color]}
            type="color"
            label={gettext("Background color")}
            class="flex-1"
          />
          <.input
            field={@form[:text_color]}
            type="color"
            label={gettext("Text color")}
            class="flex-1"
          />
        </div>
        <.card_base class="flex items-center gap-2 p-6 mb-6">
          <p class="text-ltrn-subtle">{gettext("Preview")}</p>
          <.badge color_map={
            %{bg_color: @form[:bg_color].value, text_color: @form[:text_color].value}
          }>
            {@form[:name].value}
          </.badge>
        </.card_base>
        <.error_block
          :if={@delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{@delete_error}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@ordinal_value.id}
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
  def update(%{ordinal_value: ordinal_value} = assigns, socket) do
    changeset = Grading.change_ordinal_value(assigns.current_scope, ordinal_value)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"ordinal_value" => params}, socket) do
    changeset =
      Grading.change_ordinal_value(
        socket.assigns.current_scope,
        socket.assigns.ordinal_value,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Grading.delete_ordinal_value(
             socket.assigns.current_scope,
             socket.assigns.ordinal_value
           ) do
        {:ok, ordinal_value} ->
          message = {:deleted, ordinal_value}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Ordinal value deleted"))
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

  def handle_event("save", %{"ordinal_value" => params}, socket) do
    save(socket, socket.assigns.ordinal_value, params)
  end

  defp save(socket, %OrdinalValue{id: nil}, params) do
    case Grading.create_ordinal_value(socket.assigns.current_scope, params) do
      {:ok, ordinal_value} ->
        message = {:created, ordinal_value}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Ordinal value created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save(socket, %OrdinalValue{} = ordinal_value, params) do
    case Grading.update_ordinal_value(socket.assigns.current_scope, ordinal_value, params) do
      {:ok, ordinal_value} ->
        message = {:updated, ordinal_value}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Ordinal value updated"))
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
