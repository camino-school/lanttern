defmodule LantternWeb.MessageBoard.IndexLive do
  use LantternWeb, :live_view

  import LantternWeb.CoreComponents
  import LantternWeb.MessageBoard.Components
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message
  alias Lanttern.Schools.Cycle

  # shared
  alias LantternWeb.MessageBoard.MessageFormOverlayComponent

  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :initialized)

    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:view_as_guardian, false)
      |> assign(:classes, [])
      |> assign(:selected_classes, [])
      |> assign(:selected_classes_ids, [])
      |> assign(:message, nil)
      |> assign(:messages, [])
      |> assign(:total_messages_count, 0)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)

    {:noreply, socket}
  end

  def handle_event("toggle_guardian", _params, socket) do
    {:noreply, assign(socket, view_as_guardian: !socket.assigns.view_as_guardian)}
  end

  def handle_event("create_section", _params, socket) do
    # Implementar lógica de criação de seção
    {:noreply, socket}
  end

  def handle_event("change_year_filter", %{"year" => year}, socket) do
    {:noreply,
     socket
     |> assign(year_filter: year)
     |> assign_sections()}
  end

  def handle_event("unarchive_message", %{"message_id" => message_id}, socket) do
    case MessageBoard.unarchive_message(message_id) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Message unarchived successfully"))
         |> assign_sections()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to unarchive message"))}
    end
  end

  def handle_event("delete_message", %{"message_id" => message_id}, socket) do
    case MessageBoard.delete_message(message_id) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Message deleted successfully"))
         |> assign_sections()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete message"))}
    end
  end

  # Handle message form overlay updates
  def handle_info({MessageFormOverlayComponent, {action, _message}}, socket)
      when action in [:created, :updated, :archived] do
    flash_message =
      case action do
        :created -> {:info, gettext("Message created successfully")}
        :updated -> {:info, gettext("Message updated successfully")}
        :archived -> {:info, gettext("Message archived successfully")}
      end

    {:noreply,
     socket
     |> put_flash(elem(flash_message, 0), elem(flash_message, 1))
     |> assign_sections()}
  end

  def handle_info(:initialized, socket) do
    socket =
      socket
      |> apply_assign_classes_filter()
      |> assign_sections()
      |> assign_message()
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

    sections = load_sections_data(school_id, socket.assigns.selected_classes_ids)

    socket
    |> assign(:sections, sections)
    |> assign(:total_messages_count, count_total_messages(sections))
  end

  defp load_sections_data(school_id, selected_classes_ids) do
    messages =
      MessageBoard.list_messages(
        school_id: school_id,
        classes_ids: selected_classes_ids,
        preloads: :classes
      )

    [
      %{
        id: 1,
        name: "Section name",
        messages: messages,
        messages_count: length(messages)
      }
    ]
  end

  defp count_total_messages(sections) do
    Enum.reduce(sections, 0, fn section, acc ->
      acc + section.messages_count
    end)
  end

  defp assign_message(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    message = %Message{
      school_id: socket.assigns.current_user.current_profile.school_id,
      classes: [],
      send_to: "school"
    }

    socket
    |> assign(:message, message)
    |> assign(:message_overlay_title, gettext("New message"))
  end

  defp assign_message(%{assigns: %{params: %{"edit" => message_id}}} = socket) do
    # Verificar se o usuário tem permissão e se a mensagem existe
    message = MessageBoard.get_message(message_id, preloads: :classes)

    if message do
      socket
      |> assign(:message, message)
      |> assign(:message_overlay_title, gettext("Edit message"))
    else
      assign(socket, :message, nil)
    end
  end

  defp assign_message(socket), do: assign(socket, :message, nil)

  def render(assigns) do
    ~H"""
    <div>
      <!-- School Zone Header -->
      <.header_nav current_user={@current_user}>
        <:title><%= @current_user.current_profile.school_name %></:title>
        <div class="px-4">
          <.neo_tabs>
            <:tab patch={~p"/school/classes"} is_current={@live_action == :manage_classes}>
              <%= "#{@current_user.current_profile.current_school_cycle.name} #{gettext("classes")}" %>
            </:tab>
            <:tab patch={~p"/school/students"} is_current={@live_action == :manage_students}>
              <%= gettext("Students") %>
            </:tab>
            <:tab patch={~p"/school/staff"} is_current={@live_action == :manage_staff}>
              <%= gettext("Staff") %>
            </:tab>
            <:tab patch={~p"/school/cycles"} is_current={@live_action == :manage_cycles}>
              <%= gettext("Cycles") %>
            </:tab>
            <:tab patch={~p"/school/message_board"} is_current={@live_action == :message_board}>
              <%= gettext("Message board") %>
            </:tab>
            <:tab
              patch={~p"/school/moment_cards_templates"}
              is_current={@live_action == :manage_moment_cards_templates}
            >
              <%= gettext("Templates") %>
            </:tab>
          </.neo_tabs>
        </div>
      </.header_nav>

      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <div class="flex items-center gap-4">
          <h1 class="text-2xl font-bold text-gray-800">Message board admin</h1>
          <!-- Year Filter -->
          <.action
            type="button"
            phx-click={JS.exec("data-show", to: "#message-board-classes-filters-overlay")}
            icon_name="hero-chevron-down-mini"
          >
            <%= format_action_items_text(@selected_classes, gettext("All years")) %>
          </.action>
          <!-- View as Guardian Toggle -->
          <div class="flex items-center space-x-2">
            <span class="text-sm text-gray-600">View as guardian</span>
            <button
              phx-click="toggle_guardian"
              class={[
                "relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                if(@view_as_guardian, do: "bg-blue-600", else: "bg-gray-200")
              ]}
            >
              <span class={[
                "inline-block h-3 w-3 transform rounded-full bg-white transition-transform",
                if(@view_as_guardian, do: "translate-x-5", else: "translate-x-1")
              ]}>
              </span>
            </button>
            <.icon name="hero-eye" class="w-4 h-4 text-gray-400" />
          </div>

          <p class="text-sm text-gray-600">
            <%= if @total_messages_count == 0 do
              gettext("No messages")
            else
              ngettext(
                "Showing 1 message",
                "Showing %{count} messages",
                @total_messages_count
              )
            end %>
          </p>
        </div>

        <.action type="link" patch={~p"/school/message_board_v2"} icon_name="hero-plus-circle-mini">
          <%= gettext("Create section") %>
        </.action>
      </.action_bar>

      <.responsive_container class="p-4">
        <p class="flex items-center gap-2 mb-6">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext(
            "Manage message board sections and messages. Messages are displayed in students and guardians home page."
          ) %>
        </p>

        <%= if @total_messages_count == 0 do %>
          <.card_base class="p-10 mt-4">
            <.empty_state>
              <%= gettext("No messages created yet") %>
            </.empty_state>
          </.card_base>
        <% else %>
          <!-- Sections -->
          <div class="space-y-8">
            <%= for section <- @sections do %>
              <div class="bg-white rounded-lg shadow-sm border border-gray-200">
                <!-- Section Header -->
                <div class="flex items-center justify-between p-4 border-b border-gray-200">
                  <div class="flex items-center space-x-3">
                    <.icon name="hero-bars-2" class="w-5 h-5 text-gray-400 cursor-move" />
                    <h2 class="text-lg font-semibold text-gray-800"><%= section.name %></h2>
                    <.badge><%= section.messages_count %></.badge>
                  </div>
                  <div class="flex items-center space-x-2">
                    <.action type="button" theme="subtle" icon_name="hero-cog-6-tooth-mini">
                      <%= gettext("Settings") %>
                    </.action>
                    <.action
                      type="link"
                      patch={~p"/school/message_board?new=true"}
                      theme="ghost"
                      icon_name="hero-plus-mini"
                    >
                      <%= gettext("New message") %>
                    </.action>
                  </div>
                </div>
                <!-- Messages Grid -->
                <div class="p-4">
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    <%= for message <- section.messages do %>
                      <.message_board_card
                        message={message}
                        id={"message-#{message.id}"}
                        tz={@current_user.tz}
                        show_sent_to={true}
                        class="h-48 hover:shadow-md transition-shadow"
                        edit_patch={~p"/school/message_board?edit=#{message.id}"}
                        on_unarchive={
                          if message.archived_at,
                            do: JS.push("unarchive_message", value: %{message_id: message.id})
                        }
                        on_delete={JS.push("delete_message", value: %{message_id: message.id})}
                      />
                    <% end %>
                    <!-- Add New Message Card -->
                    <.link
                      patch={~p"/school/message_board?new=true&section=#{section.id}"}
                      class="bg-white border-2 border-dashed border-gray-300 rounded-lg p-6 h-48 flex flex-col items-center justify-center text-gray-400 hover:text-gray-600 hover:border-gray-400 transition-colors group"
                    >
                      <.icon
                        name="hero-plus"
                        class="w-12 h-12 mb-4 group-hover:scale-110 transition-transform"
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
      <!-- Message Form Overlay -->
      <.live_component
        :if={@message}
        module={MessageFormOverlayComponent}
        id="message-form-overlay"
        message={@message}
        title={@message_overlay_title}
        current_profile={@current_user.current_profile}
        on_cancel={JS.patch(~p"/school/message_board_v2")}
        notify_parent={self()}
      />
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="message-board-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter messages by class")}
        navigate={~p"/school/message_board_v2"}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
    </div>
    """
  end
end
