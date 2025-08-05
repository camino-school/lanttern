defmodule LantternWeb.MessageBoard.MessageFormOverlayComponentV2 do
  @moduledoc """
  Renders an overlay with a `Message` form

  ### Attrs

      attr :message, Message, required: true
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :section_id, :string
      attr :section, :string
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message
  alias Lanttern.SupabaseHelpers

  # shared

  alias LantternWeb.Schools.ClassesFieldComponent
  import LantternWeb.FormComponents

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
            field={@form[:name]}
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
          <.image_field
            current_image_url={@message.cover}
            is_removing={@is_removing_cover}
            upload={@uploads.cover}
            on_cancel_replace={JS.push("cancel-replace-cover", target: @myself)}
            on_cancel_upload={JS.push("cancel-upload", target: @myself)}
            on_replace={JS.push("replace-cover", target: @myself)}
            class="mb-6"
          />
          <.input
            field={@form[:description]}
            type="markdown"
            label={gettext("Description")}
            class="mb-6"
            phx-debounce="1500"
          />
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
    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:is_removing_cover, false)
      |> allow_upload(:cover,
        accept: ~w(.jpg .jpeg .png .webp),
        max_file_size: 5_000_000,
        max_entries: 1
      )

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
  def handle_event("validate", %{"message" => message_params}, socket) do
    {:noreply, assign_validated_form(socket, message_params)}
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    params = inject_extra_params(socket.assigns, message_params)

    if socket.assigns.is_removing_cover == true do
      SupabaseHelpers.remove_object("covers", socket.assigns.message.cover)
    end

    cover_image_url =
      consume_uploaded_entries(socket, :cover, fn %{path: file_path}, entry ->
        {:ok, object} =
          SupabaseHelpers.upload_object(
            "covers",
            entry.client_name,
            file_path,
            %{content_type: entry.client_type}
          )

        image_url =
          "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object.key)}"

        {:ok, image_url}
      end)
      |> case do
        [] -> nil
        [image_url] -> image_url
      end

    # besides "consumed" cover image, we should also consider is_removing_cover flag
    cover_image_url =
      cond do
        cover_image_url -> cover_image_url
        socket.assigns.is_removing_cover -> nil
        true -> socket.assigns.message.cover
      end

    params =
      params
      |> Map.put("cover", cover_image_url)

    save_message(socket, socket.assigns.message.id, params)
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover, ref)}
  end

  def handle_event("replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, true)}
  end

  def handle_event("cancel-replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, false)}
  end

  defp save_message(socket, nil, message_params) do
    message_params
    |> MessageBoard.create_message()
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

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket.assigns, params)

    changeset =
      socket.assigns.message
      |> MessageBoard.change_message(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp inject_extra_params(assigns, params) do
    params
    |> Map.put("school_id", assigns.message.school_id)
    |> Map.put("classes_ids", assigns.selected_classes_ids)
    |> Map.put("section", assigns.section)
  end
end
