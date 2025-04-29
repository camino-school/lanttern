defmodule LantternWeb.MessageBoard.MessageFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Message` form

  ### Attrs

      attr :message, Message, required: true
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message

  # shared

  alias LantternWeb.Schools.ClassesFieldComponent

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
          <div class="p-4 rounded-xs mb-6 bg-ltrn-mesh-cyan">
            <.input
              field={@form[:is_pinned]}
              type="toggle"
              theme="primary"
              label={gettext("Pin message")}
            />
            <p class="mt-4">
              <%= gettext("Pinned messages are displayed at the top of the message board.") %>
            </p>
          </div>
          <%!-- allow send to selection only when creating message --%>
          <%= if @message.id do %>
            <div :if={@message.send_to == "school"} class="flex items-center gap-2 mb-6">
              <.icon name="hero-user-group" class="w-6 h-6" />
              <p class="font-bold"><%= gettext("Sending to all school") %></p>
            </div>
            <div :if={@message.send_to == "classes"} class="flex items-center gap-2 mb-6">
              <.icon name="hero-users" class="w-6 h-6" />
              <p class="font-bold"><%= gettext("Sending to selected classes") %></p>
            </div>
          <% else %>
            <fieldset class="mb-6">
              <legend class="font-bold"><%= gettext("Send to") %></legend>
              <div class="mt-4 flex items-center gap-4">
                <.radio_input field={@form[:send_to]} value="school" label={gettext("All school")} />
                <.radio_input
                  field={@form[:send_to]}
                  value="classes"
                  label={gettext("Selected classes")}
                />
              </div>
              <.error :for={msg <- Enum.map(@form[:send_to].errors, &translate_error(&1))}>
                <%= msg %>
              </.error>
            </fieldset>
          <% end %>
          <.live_component
            module={ClassesFieldComponent}
            id="message-form-classes-picker"
            label={gettext("Classes")}
            school_id={@message.school_id}
            current_cycle={@current_profile.current_school_cycle}
            selected_classes_ids={@selected_classes_ids}
            notify_component={@myself}
            class={[
              if(@form[:classes_ids].errors == [] && @form.source.action not in [:insert, :update],
                do: "mb-6"
              ),
              if(@form[:send_to].value != "classes", do: "hidden")
            ]}
          />
          <div
            :if={@form[:classes_ids].errors != [] && @form.source.action in [:insert, :update]}
            class="mb-6"
          >
            <.error :for={msg <- Enum.map(@form[:classes_ids].errors, &translate_error(&1))}>
              <%= msg %>
            </.error>
          </div>
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors above.") %>
          </.error_block>
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
  def update(
        %{action: {ClassesFieldComponent, {:changed, selected_classes_ids}}},
        socket
      ) do
    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:ok, socket}
  end

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

    socket
    |> assign(:form, to_form(changeset))
    |> assign_selected_classes_ids()
  end

  defp assign_selected_classes_ids(socket) do
    selected_classes_ids =
      socket.assigns.message.classes
      |> Enum.map(& &1.id)

    assign(socket, :selected_classes_ids, selected_classes_ids)
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
    |> Map.put("classes_ids", socket.assigns.selected_classes_ids)
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
