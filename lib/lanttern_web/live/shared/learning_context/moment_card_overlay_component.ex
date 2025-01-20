defmodule LantternWeb.LearningContext.MomentCardOverlayComponent do
  @moduledoc """
  Renders an overlay with `MomentCard` details and editing support.

  ### Supported attrs/assigns

  - `moment_card` (required, `%MomentCard{}`)
  - `on_cancel` (required, function)
  - `allow_edit` (required, boolean)
  - supports `notify` attrs (`notify_parent`, `notify_component`)
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  # alias Lanttern.SchoolConfig

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show on_cancel={@on_cancel}>
        <h5 class="mb-10 font-display font-black text-xl">
          <%= case {@is_editing, @moment_card} do
            {true, %{id: nil}} -> gettext("New moment card")
            {true, _} -> gettext("Edit moment card")
            {false, %{name: name}} -> name
          end %>
        </h5>
        <%= if @is_editing && @allow_edit do %>
          <.scroll_to_top overlay_id={@id} id="form-scroll-top" />
          <.form
            :if={@is_editing}
            id="moment-card-form"
            for={@form}
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
          >
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              <%= gettext("Oops, something went wrong! Please check the errors below.") %>
            </.error_block>
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
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              <%= gettext("Oops, something went wrong! Please check the errors above.") %>
            </.error_block>
            <div class="flex items-center justify-end gap-6">
              <.action
                type="button"
                theme="subtle"
                size="md"
                phx-click={
                  if(is_nil(@moment_card.id),
                    do: JS.exec("data-cancel", to: "##{@id}"),
                    else: JS.push("cancel_edit", target: @myself)
                  )
                }
              >
                <%= gettext("Cancel") %>
              </.action>
              <.action type="submit" theme="primary" size="md" icon_name="hero-check">
                <%= gettext("Save") %>
              </.action>
            </div>
          </.form>
        <% else %>
          <.scroll_to_top overlay_id={@id} id="details-scroll-top" />
          <.markdown text={@moment_card.description} class="mt-6" />
          <%= if @is_deleted do %>
            <.error_block class="mt-10">
              <%= gettext("This card was deleted") %>
            </.error_block>
          <% else %>
            <div :if={@allow_edit} class="flex justify-between gap-4 mt-10">
              <.action
                type="button"
                icon_name="hero-x-circle-mini"
                phx-click={JS.push("delete", target: @myself)}
                theme="subtle"
                data-confirm={gettext("Are you sure?")}
              >
                <%= gettext("Delete") %>
              </.action>
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                phx-click={JS.push("edit", target: @myself)}
              >
                <%= gettext("Edit card") %>
              </.action>
            </div>
          <% end %>
        <% end %>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:is_deleted, false)
      |> assign(:allow_edit, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_initial_is_editing()
      |> assign(:initialized, false)

    {:ok, socket}
  end

  defp assign_initial_is_editing(%{assigns: %{moment_card: %{id: nil}}} = socket) do
    socket
    |> assign_form()
    |> assign(:is_editing, true)
  end

  defp assign_initial_is_editing(socket),
    do: assign(socket, :is_editing, false)

  defp assign_form(socket) do
    changeset = LearningContext.change_moment_card(socket.assigns.moment_card)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign_form()
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("validate", %{"moment_card" => moment_card_params}, socket),
    do: {:noreply, assign_validated_form(socket, moment_card_params)}

  def handle_event("save", %{"moment_card" => moment_card_params}, socket) do
    save_moment_card(
      socket,
      socket.assigns.moment_card.id,
      moment_card_params
    )
  end

  def handle_event("delete", _, socket) do
    LearningContext.delete_moment_card(socket.assigns.moment_card)
    |> case do
      {:ok, _moment_card} ->
        # we notify using the assigned moment card
        notify(__MODULE__, {:deleted, socket.assigns.moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:is_deleted, true)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    changeset =
      socket.assigns.moment_card
      |> LearningContext.change_moment_card(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_moment_card(socket, nil, moment_card_params) do
    # inject moment id to params
    moment_card_params =
      Map.put_new(
        moment_card_params,
        "moment_id",
        socket.assigns.moment_card.moment_id
      )

    LearningContext.create_moment_card(moment_card_params)
    |> case do
      {:ok, moment_card} ->
        notify(__MODULE__, {:created, moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card, moment_card)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_moment_card(socket, _id, moment_card_params) do
    LearningContext.update_moment_card(
      socket.assigns.moment_card,
      moment_card_params
    )
    |> case do
      {:ok, moment_card} ->
        notify(__MODULE__, {:updated, moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card, moment_card)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
