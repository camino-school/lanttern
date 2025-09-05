defmodule LantternWeb.MessageBoard.IndexLive do
  use LantternWeb, :live_view

  import LantternWeb.CoreComponents
  import LantternWeb.MessageBoard.Components
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Schools.Cycle

  # shared
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.MessageBoard.MessageFormOverlayComponent

  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :initialized)

    communication_manager? =
      "communication_management" in socket.assigns.current_user.current_profile.permissions

    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:show_reorder, false)
      |> assign(:classes, [])
      |> assign(:selected_classes, [])
      |> assign(:selected_classes_ids, [])
      |> assign(:message, nil)
      |> assign(:messages, [])
      |> assign(:section, nil)
      |> assign(:section_id, nil)
      |> assign(:sections, [])
      |> assign(:communication_manager?, communication_manager?)
      |> assign(:section_overlay_title, nil)
      |> assign(:form_action, nil)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_message()
      |> assign_section()
      |> assign_reorder()

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message_id" => id}, socket) do
    message = MessageBoard.get_message!(id)

    case MessageBoard.delete_message(message) do
      {:ok, _message} ->
        socket
        |> put_flash(:info, gettext("Message deleted successfully"))
        |> assign_sections()
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete message"))}
    end
  end

  def handle_event("validate_section", %{"section" => section_params}, socket) do
    changeset =
      socket.assigns.section
      |> MessageBoard.change_section(section_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save_section", params, %{assigns: %{form_action: :edit}} = socket) do
    section_params = Map.get(params, "section")

    socket.assigns.section
    |> MessageBoard.update_section(section_params)
    |> case do
      {:ok, _section} ->
        socket
        |> put_flash(:info, "Section updated successfully")
        |> push_patch(to: ~p"/school/message_board")
        |> assign_sections()
        |> assign(:form_action, nil)
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("save_section", params, %{assigns: %{form_action: :create}} = socket) do
    section_params =
      params
      |> Map.get("section")
      |> Map.put("school_id", socket.assigns.current_user.current_profile.school_id)

    section_params
    |> MessageBoard.create_section()
    |> case do
      {:ok, _section} ->
        socket
        |> put_flash(:info, "Section created successfully")
        |> push_patch(to: ~p"/school/message_board")
        |> assign_sections()
        |> assign(:form_action, nil)
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_section", _params, %{assigns: %{section: section}} = socket) do
    case MessageBoard.delete_section(section) do
      {:ok, _section} ->
        socket
        |> put_flash(:info, gettext("Section deleted successfully"))
        |> push_patch(to: ~p"/school/message_board")
        |> assign_sections()
        |> assign(:form_action, nil)
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete section"))}
    end
  end

  def handle_event("sortable_update", %{"oldIndex" => old, "newIndex" => new}, socket) do
    {changed_id, rest} = List.pop_at(socket.assigns.section.messages, old)
    new_messages = List.insert_at(rest, new, changed_id)
    MessageBoard.update_messages_position(new_messages)

    {:noreply, assign_sections(socket)}
  end

  def handle_info({MessageFormOverlayComponent, {action, _message}}, socket)
      when action in [:created, :updated] do
    flash_message =
      case action do
        :created -> {:info, gettext("Message created successfully")}
        :updated -> {:info, gettext("Message updated successfully")}
      end

    socket
    |> put_flash(elem(flash_message, 0), elem(flash_message, 1))
    |> push_patch(to: ~p"/school/message_board")
    |> assign_sections()
    |> then(&{:noreply, &1})
  end

  def handle_info({MessageFormOverlayComponent, {:archived, _message}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Message archived"))
      |> push_patch(to: ~p"/school/message_board")
      |> assign_sections()

    {:noreply, socket}
  end

  def handle_info({MessageFormOverlayComponent, {:unarchived, _message}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Message restored"))
      |> push_patch(to: ~p"/school/message_board")
      |> assign_sections()

    {:noreply, socket}
  end

  def handle_info({AttachmentAreaComponent, {_action, _attachment}}, socket) do
    {:noreply, socket}
  end

  def handle_info({LantternWeb.MessageBoard.ReorderComponent, :reordered}, socket) do
    {:noreply, assign_sections(socket)}
  end

  def handle_info(:initialized, socket) do
    socket =
      socket
      |> apply_assign_classes_filter()
      |> assign_sections()
      |> assign(:initialized, true)

    {:noreply, socket}
  end

  defp apply_assign_classes_filter(socket) do
    assign_classes_filter_opts =
      case socket.assigns.current_user.current_profile do
        %{current_school_cycle: %Cycle{} = cycle} -> [cycles_ids: [cycle.id]]
        _ -> []
      end

    assign_classes_filter(socket, assign_classes_filter_opts)
  end

  defp assign_sections(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    sections = MessageBoard.list_sections(school_id, socket.assigns.selected_classes_ids)

    assign(socket, :sections, sections)
  end

  defp assign_section(%{assigns: %{params: %{"new_section" => "true"}}} = socket) do
    section = %Section{}
    changeset = MessageBoard.change_section(section)

    socket
    |> assign(:section, section)
    |> assign(:section_overlay_title, gettext("New section"))
    |> assign(:form_action, :create)
    |> assign(:form, to_form(changeset))
  end

  defp assign_section(%{assigns: %{params: %{"edit_section" => id}}} = socket) do
    section = MessageBoard.get_section!(id) |> Lanttern.Repo.preload(:messages)
    changeset = MessageBoard.change_section(section)

    socket
    |> assign(:section, section)
    |> assign(:section_overlay_title, gettext("Edit section"))
    |> assign(:form_action, :edit)
    |> assign(:form, to_form(changeset))
  end

  defp assign_section(%{assigns: %{params: %{"section_id" => section_id}}} = socket) do
    section = MessageBoard.get_section!(section_id)

    assign(socket, :section_id, section.id)
  end

  defp assign_section(socket), do: assign(socket, :section, nil)

  defp assign_message(%{assigns: %{communication_manager?: false}} = socket),
    do: assign(socket, :message, nil)

  defp assign_message(%{assigns: %{params: %{"new" => "true", "section_id" => id}}} = socket) do
    message = %Message{
      school_id: socket.assigns.current_user.current_profile.school_id,
      classes: [],
      send_to: "school",
      section_id: id
    }

    socket
    |> assign(:message, message)
    |> assign(:message_overlay_title, gettext("New message"))
  end

  defp assign_message(%{assigns: %{params: %{"edit" => message_id}}} = socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    with true <- socket.assigns.communication_manager?,
         {:ok, message} <- MessageBoard.get_message_per_school(message_id, school_id) do
      socket
      |> assign(:message, message)
      |> assign(:message_overlay_title, gettext("Edit message"))
    else
      _ -> assign(socket, :message, nil)
    end
  end

  defp assign_message(socket), do: assign(socket, :message, nil)

  defp assign_reorder(%{assigns: %{params: %{"reorder" => "true"}}} = socket) do
    assign(socket, :show_reorder, true)
  end

  defp assign_reorder(socket), do: assign(socket, :show_reorder, false)

  def render(assigns) do
    ~H"""
    <Layouts.app_logged_in flash={@flash} current_user={@current_user} current_path={@current_path}>
      <.header_nav current_user={@current_user}>
        <:title>{gettext("Message board admin")}</:title>
        <div class="flex items-center justify-between gap-4 p-4">
          <div class="flex items-center gap-4">
            <.action
              type="button"
              phx-click={JS.exec("data-show", to: "#message-board-classes-filters-overlay")}
              icon_name="hero-chevron-down-mini"
            >
              {format_action_items_text(@selected_classes, gettext("All years"))}
            </.action>
            <.action
              type="link"
              patch={~p"/school/message_board/archive"}
              icon_name="hero-archive-box-solid"
            >
              {gettext("View archived messages")}
            </.action>
          </div>
          <div class="flex items-center gap-4">
            <.action
              type="link"
              patch={~p"/school/message_board?reorder=true"}
              icon_name="hero-arrows-up-down-mini"
            >
              {gettext("Reorder sections")}
            </.action>
            <.action
              type="link"
              patch={~p"/school/message_board?new_section=true"}
              icon_name="hero-plus-circle-mini"
            >
              {gettext("Create section")}
            </.action>
          </div>
        </div>
      </.header_nav>

      <.responsive_container class="p-4">
        <p class="flex items-center gap-2 mb-6">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          {gettext(
            "Manage message board sections and messages. Messages are displayed in students and guardians home page."
          )}
        </p>

        <%= if @sections == [] do %>
          <.card_base class="p-10 mt-4">
            <.empty_state>
              {gettext("No sections created yet")}
            </.empty_state>
          </.card_base>
        <% else %>
          <div class="space-y-8">
            <%= for section <- @sections do %>
              <div class="bg-white rounded-lg shadow-lg">
                <div class="flex items-center justify-between p-4 border-gray-200">
                  <div class="flex items-center space-x-3">
                    <%!-- <.icon name="hero-bars-2" class="w-5 h-5 text-gray-400 cursor-move" /> --%>
                    <h2 class="text-lg font-bold">{section.name}</h2>
                  </div>
                  <div class="flex items-center space-x-2">
                    <.action
                      type="link"
                      patch={~p"/school/message_board?edit_section=#{section.id}"}
                      theme="subtle"
                      icon_name="hero-cog-6-tooth-mini"
                      id={"section-#{section.id}-settings"}
                    >
                    </.action>
                  </div>
                </div>
                <div class="p-4">
                  <div
                    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 gap-4"
                    id={"section-#{section.id}-messages"}
                  >
                    <%= for message <- section.messages do %>
                      <.message_card_admin
                        message={message}
                        mode="admin"
                        edit_patch={~p"/school/message_board?edit=#{message.id}"}
                        on_delete={JS.push("delete_message", value: %{message_id: message.id})}
                      />
                    <% end %>

                    <.link
                      :if={@communication_manager?}
                      patch={~p"/school/message_board?new=true&section_id=#{section.id}"}
                      class="aspect-square w-full bg-white border-1 border-dashed border-gray-300 rounded-lg p-6 h-48 flex flex-col items-center justify-center text-gray-400 hover:text-gray-600 hover:border-gray-400 transition-colors group shadow-lg"
                    >
                      <.icon
                        name="hero-plus"
                        class="w-12 h-12 aspect-square mb-4 group-hover:scale-110 transition-transform"
                      />
                      <span class="text-sm font-medium">Add new message</span>
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </.responsive_container>

      <.live_component
        :if={@message}
        module={MessageFormOverlayComponent}
        id="message-form-overlay"
        message={@message}
        section_id={@section_id}
        title={@message_overlay_title}
        current_profile={@current_user.current_profile}
        on_cancel={JS.patch(~p"/school/message_board")}
        notify_parent
      />

      <div :if={@section} phx-remove={JS.exec("phx-remove", to: "#section-form-overlay")}>
        <.slide_over
          id="section-form-overlay"
          show={true}
          on_cancel={JS.patch(~p"/school/message_board")}
        >
          <:title>{@section_overlay_title}</:title>
          <.form
            id="message-form"
            for={@form}
            phx-change="validate_section"
            phx-submit="save_section"
          >
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              {gettext("Oops, something went wrong! Please check the errors below.")}
            </.error_block>
            <.input
              field={@form[:name]}
              type="text"
              label={gettext("Section name")}
              class="mb-6"
              phx-debounce="1500"
            />
          </.form>
          <div
            :if={@form_action == :edit}
            phx-hook="Sortable"
            id="sortable-section-cards"
            data-sortable-handle=".sortable-handle"
            phx-update="ignore"
          >
            <.dragable_card
              :for={message <- @section.messages}
              id={"sortable-#{message.id}"}
              class={"border-[#{message.color}] mb-4 border-l-5 border-1"}
            >
              {message.name}
            </.dragable_card>
          </div>
          <:actions_left :if={@section.id}>
            <.action
              type="button"
              theme="subtle"
              size="md"
              phx-click="delete_section"
              data-confirm={gettext("Are you sure? All messages in this section will be deleted.")}
            >
              {gettext("Delete")}
            </.action>
          </:actions_left>
          <:actions>
            <.action
              type="button"
              theme="subtle"
              size="md"
              phx-click={JS.exec("data-cancel", to: "#section-form-overlay")}
            >
              {gettext("Cancel")}
            </.action>
            <.action
              type="submit"
              theme="primary"
              size="md"
              icon_name="hero-check"
              form="message-form"
            >
              {gettext("Save")}
            </.action>
          </:actions>
        </.slide_over>
      </div>

      <.slide_over
        :if={@show_reorder}
        id="reorder-sections-overlay"
        show={true}
        on_cancel={JS.patch(~p"/school/message_board")}
      >
        <:title>{gettext("Reorder sections")}</:title>
        <.live_component
          module={LantternWeb.MessageBoard.ReorderComponent}
          id="reorder-sections-component"
          current_user={@current_user}
        />
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "#reorder-sections-overlay")}
          >
            {gettext("Cancel")}
          </.action>
          <.action
            type="button"
            theme="primary"
            size="md"
            phx-click={JS.patch(~p"/school/message_board")}
          >
            {gettext("Done")}
          </.action>
        </:actions>
      </.slide_over>

      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="message-board-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter messages by class")}
        navigate={~p"/school/message_board"}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
    </Layouts.app_logged_in>
    """
  end
end
