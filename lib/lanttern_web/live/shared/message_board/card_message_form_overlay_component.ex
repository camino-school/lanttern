defmodule LantternWeb.MessageBoard.CardMessageFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Message` form

  ### Attrs

      attr :message, Message, required: true
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :section_id, :string
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.CardMessage
  # alias Lanttern.MessageBoard.Message

  # shared

  # alias LantternWeb.Schools.ClassesFieldComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <%!-- <.slide_over id={@id} show={@form.action == nil} on_cancel={@on_cancel}> --%>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="message-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <%!-- <%= @section %> --%>
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:title]}
            type="text"
            label={gettext("Message title")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:subtitle]}
            type="text"
            label={gettext("Message subtitle")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:color]}
            type="text"
            label={gettext("Message color")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:cover]}
            type="text"
            label={gettext("Message cover")}
            class="mb-6"
            phx-debounce="1500"
          />
          <%!-- <.image_field
            current_image_url={@message.cover}
            is_removing={@is_removing_cover}
            upload={@uploads.cover}
            on_cancel_replace={JS.push("cancel-replace-cover", target: @myself)}
            on_cancel_upload={JS.push("cancel-upload", target: @myself)}
            on_replace={JS.push("replace-cover", target: @myself)}
            class="mb-6"
          /> --%>
          <.input
            field={@form[:content]}
            type="markdown"
            label={gettext("Content")}
            class="mb-6"
            phx-debounce="1500"
          />
          <%!-- <div class="p-4 rounded-xs mb-6 bg-ltrn-mesh-cyan">
            <.input
              field={@form[:is_pinned]}
              type="toggle"
              theme="primary"
              label={gettext("Pin message")}
            />
            <p class="mt-4">
              <%= gettext("Pinned messages are displayed at the top of the message board.") %>
            </p>
          </div> --%>
          <%!-- allow send to selection only when creating message --%>
        </.form>
        <:actions_left :if={@message.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <%= gettext("Cancel") %>
          </.action>
          <.action type="submit" theme="primary" size="md" icon_name="hero-check" form="message-form">
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket = assign(socket, :initialized, false)
    {:ok, socket}
  end

  @impl true
  # def update(
  #       %{action: {ClassesFieldComponent, {:changed, selected_classes_ids}}},
  #       socket
  #     ) do
  #   socket =
  #     socket
  #     |> assign(:selected_classes_ids, selected_classes_ids)
  #     |> assign_validated_form(socket.assigns.form.params)

  #   {:ok, socket}
  # end

  def update(%{message: %CardMessage{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    message = socket.assigns.message
    changeset = MessageBoard.change_card_message(message)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"card_message" => message_params}, socket) do
    socket.assigns.message
    |> MessageBoard.change_card_message(message_params)
    |> Map.put(:action, :validate)

    {:noreply, socket}
  end

  def handle_event("save", %{"card_message" => message_params}, socket) do
    # message_params =
    #   inject_extra_params(socket, message_params)
    params = Map.put(message_params, "card_section_id", socket.assigns.section.id)

    save_message(socket, socket.assigns.message.id, params)
  end

  def handle_event("delete", _, socket) do
    MessageBoard.delete_card_message(socket.assigns.message)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:deleted, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_message(socket, nil, message_params) do
    MessageBoard.create_card_message(message_params)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:created, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_message(socket, _id, message_params) do
    MessageBoard.update_card_message(
      socket.assigns.message,
      message_params
    )
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:updated, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
