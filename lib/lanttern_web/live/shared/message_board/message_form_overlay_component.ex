defmodule LantternWeb.MessageBoard.MessageFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Message` form

  ### Attrs

      attr :message, Message, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="message-form"
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
            label={gettext("Message title")}
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
        </.form>
        <:actions_left :if={@message.id}>
          <.action
            :if={@message.archived_at}
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
          <.action
            :if={is_nil(@message.archived_at)}
            type="button"
            theme="subtle"
            size="md"
            phx-click="archive"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? You can unarchive the message later.")}
          >
            <%= gettext("Archive") %>
          </.action>
          <.action
            :if={@message.archived_at}
            type="button"
            theme="subtle"
            size="md"
            phx-click="unarchive"
            phx-target={@myself}
          >
            <%= gettext("Unarchive") %>
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
  #     ),
  #     do: {:ok, assign(socket, :selected_classes_ids, selected_classes_ids)}

  def update(%{message: %Message{}} = assigns, socket) do
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
    changeset = MessageBoard.change_message(message)

    # selected_classes_ids = Enum.map(message.classes, & &1.id)

    socket
    |> assign(:form, to_form(changeset))

    # |> assign(:selected_classes_ids, selected_classes_ids)
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"message" => message_params}, socket),
    do: {:noreply, assign_validated_form(socket, message_params)}

  def handle_event("save", %{"message" => message_params}, socket) do
    message_params =
      inject_extra_params(socket, message_params)

    save_message(socket, socket.assigns.message.id, message_params)
  end

  def handle_event("delete", _, socket) do
    MessageBoard.delete_message(socket.assigns.message)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:deleted, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("archive", _, socket) do
    MessageBoard.archive_message(socket.assigns.message)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:archived, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("unarchive", _, socket) do
    MessageBoard.unarchive_message(socket.assigns.message)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:unarchived, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.message
      |> MessageBoard.change_message(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.message.school_id)
    |> Map.put("send_to", "school")
  end

  defp save_message(socket, nil, message_params) do
    MessageBoard.create_message(message_params)
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:created, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_message(socket, _id, message_params) do
    MessageBoard.update_message(
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
