defmodule LantternWeb.GradingScalesLive.OrdinalValueFormComponent do
  @moduledoc """
  Form component for creating and editing ordinal values within a grading scale.
  """

  use LantternWeb, :live_component

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue

  @impl Phoenix.LiveComponent
  def update(%{ordinal_value: ordinal_value} = assigns, socket) do
    changeset = Grading.change_ordinal_value(ordinal_value)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"ordinal_value" => params}, socket) do
    changeset =
      Grading.change_ordinal_value(socket.assigns.ordinal_value, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"ordinal_value" => params}, socket) do
    save(socket, socket.assigns.ordinal_value, params)
  end

  defp save(socket, %OrdinalValue{id: nil}, params) do
    case Grading.create_ordinal_value(params) do
      {:ok, ordinal_value} ->
        notify_parent({:saved, ordinal_value})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save(socket, %OrdinalValue{} = ordinal_value, params) do
    case Grading.update_ordinal_value(ordinal_value, params) do
      {:ok, ordinal_value} ->
        notify_parent({:saved, ordinal_value})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.error :if={@form.source.action}>
          {gettext("Oops, something went wrong! Please check the errors below.")}
        </.error>
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input
          field={@form[:normalized_value]}
          type="number"
          label={gettext("Normalized value (0 to 1)")}
          step="0.01"
          min="0"
          max="1"
        />
        <.input field={@form[:scale_id]} type="hidden" />
        <div class="flex gap-6">
          <.input field={@form[:bg_color]} type="color" label={gettext("Background color")} />
          <.input field={@form[:text_color]} type="color" label={gettext("Text color")} />
        </div>
        <:actions>
          <.button phx-disable-with={gettext("Saving...")}>
            {if @ordinal_value.id, do: gettext("Save"), else: gettext("Create")}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
