defmodule LantternWeb.LearningContext.MomentCardFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="moment-card-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error_block>
        <%= if @is_admin do %>
          <.input
            field={@form[:moment_id]}
            type="select"
            label={gettext("Moment")}
            prompt={gettext("Select moment")}
            options={@moment_options}
            class="mb-6"
          />
        <% else %>
          <.input field={@form[:moment_id]} type="hidden" />
        <% end %>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          class="mb-1"
          phx-debounce="1500"
        />
        <.markdown_supported class="mb-6" />
        <div :if={@is_admin} class="mt-6">
          <.input field={@form[:position]} type="number" label={gettext("Position")} class="mb-6" />
          <div class="flex justify-end">
            <.button type="submit" phx-disable-with={gettext("Saving...")}>
              <%= gettext("Save moment card") %>
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
      |> assign(:is_admin, false)

    {:ok, socket}
  end

  @impl true
  def update(%{moment_card: moment_card} = assigns, socket) do
    moment_options =
      case assigns do
        %{is_admin: true} ->
          LearningContext.list_moments()
          |> Enum.map(&{&1.name, &1.id})

        _ ->
          []
      end

    changeset = LearningContext.change_moment_card(moment_card)

    socket =
      socket
      |> assign(assigns)
      |> assign(:moment_options, moment_options)
      |> assign_form(changeset)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"moment_card" => moment_card_params}, socket) do
    changeset =
      socket.assigns.moment_card
      |> LearningContext.change_moment_card(moment_card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"moment_card" => moment_card_params}, socket) do
    save_moment_card(socket, socket.assigns.moment_card.id, moment_card_params)
  end

  defp save_moment_card(socket, nil, moment_card_params) do
    case LearningContext.create_moment_card(moment_card_params) do
      {:ok, moment_card} ->
        notify_parent(__MODULE__, {:saved, moment_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Moment card created successfully"))
          |> handle_navigation(moment_card)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_moment_card(socket, _moment_card_id, moment_card_params) do
    case LearningContext.update_moment_card(socket.assigns.moment_card, moment_card_params) do
      {:ok, moment_card} ->
        notify_parent(__MODULE__, {:saved, moment_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Moment card updated successfully"))
          |> handle_navigation(moment_card)

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
