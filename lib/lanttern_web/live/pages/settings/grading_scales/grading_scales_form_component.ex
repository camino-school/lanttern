defmodule LantternWeb.GradingScalesFormComponent do
  @moduledoc """
  Form component for creating and editing grading scales.
  """

  use LantternWeb, :live_component

  alias Lanttern.Grading

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"scale" => scale_params}, socket) do
    case socket.assigns.action do
      :new ->
        case Grading.create_scale(scale_params) do
          {:ok, _scale} ->
            {:noreply,
             socket
             |> put_flash(:info, "Scale created successfully.")
             |> push_navigate(to: ~p"/settings/grading_scales")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end

      :edit ->
        case Grading.update_scale(socket.assigns.scale, scale_params) do
          {:ok, _scale} ->
            {:noreply,
             socket
             |> put_flash(:info, "Scale updated successfully.")
             |> push_navigate(to: ~p"/settings/grading_scales")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= if @action == :new, do: "New Scale", else: "Edit Scale" %>
      </.header>

      <.simple_form :let={f} for={@changeset} phx-submit="save" phx-target={@myself}>
        <.error :if={@changeset.action}>
          Oops, something went wrong! Please check the errors below.
        </.error>
        <.input field={f[:name]} type="text" label="Name" />
        <.input
          field={f[:type]}
          type="select"
          label="Type"
          options={[Numeric: "numeric", Ordinal: "ordinal"]}
          prompt="Select a scale type"
        />
        <.input field={f[:start]} type="number" label="Start" step="any" />
        <div class="flex gap-6">
          <.input field={f[:start_bg_color]} type="color" label="Start background color" />
          <.input field={f[:start_text_color]} type="color" label="Start text color" />
        </div>
        <.input field={f[:stop]} type="number" label="Stop" step="any" />
        <div class="flex gap-6">
          <.input field={f[:stop_bg_color]} type="color" label="Stop background color" />
          <.input field={f[:stop_text_color]} type="color" label="Stop text color" />
        </div>
        <div phx-feedback-for="scale[breakpoints]">
          <.label>Breakpoints</.label>
          <%= for n <- 0..4 do %>
            <input
              type="number"
              step="0.01"
              max="1"
              name="scale[breakpoints][]"
              value={Enum.at(f[:breakpoints].value || [], n)}
              class={[
                "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
                "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400"
              ]}
            />
          <% end %>
          <.error :for={
            msg <-
              Enum.map(f[:breakpoints].errors, fn {msg, opts} ->
                Gettext.dgettext(Lanttern.Gettext, "errors", msg, opts)
              end)
          }>
            {msg}
          </.error>
        </div>
        <:actions>
          <.button>Save Scale</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
