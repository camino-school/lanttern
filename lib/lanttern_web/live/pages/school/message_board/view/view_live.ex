defmodule LantternWeb.MessageBoard.ViewLive do
  use LantternWeb, :live_view

  alias Lanttern.MessageBoard
  alias Lanttern.Repo
  alias Lanttern.Schools.Cycle
  alias LantternWeb.MessageBoard.CardMessageOverlayComponent
  alias LantternWeb.MessageBoard.MessageBoardGridComponent
  import Ecto.Query
  import LantternWeb.MessageBoard.Components
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :initialized)

    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:classes, [])
      |> assign(:selected_classes, [])
      |> assign(:selected_classes_ids, [])
      |> assign(:sections, [])
      |> assign(:card_message, nil)

    {:ok, socket}
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

  @impl true
  def handle_event("card_lookout", %{"id" => id}, socket) do
    socket =
      socket
      |> push_patch(to: ~p"/school/message_board/view?message=#{id}")

    {:noreply, socket}
  end

  def handle_params(%{"message" => message_id}, _uri, socket) do
    card_message = MessageBoard.get_message!(message_id)
    socket = assign(socket, :card_message, card_message)

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    socket = assign(socket, :card_message, nil)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_logged_in flash={@flash} current_user={@current_user} current_path={@current_path}>
      <.header_nav current_user={@current_user}>
        <:breadcrumb navigate={~p"/school/message_board"}>
          {gettext("Message board admin")}
        </:breadcrumb>
        <:title>{gettext("View messages")}</:title>
        <div class="flex items-center justify-between gap-4 p-4">
          <div class="flex items-center gap-4">
            <.action
              type="button"
              phx-click={JS.exec("data-show", to: "#message-board-classes-filters-overlay")}
              icon_name="hero-chevron-down-mini"
            >
              {format_action_items_text(@selected_classes, gettext("All years"))}
            </.action>
          </div>
        </div>
      </.header_nav>

      <.responsive_container class="p-4">
        <p class="flex items-center gap-2 mb-6">
          <.icon name="hero-eye-mini" class="text-ltrn-subtle" />
          {gettext("This is how the message board appears to students and guardians.")}
        </p>

        <%= if @sections == [] do %>
          <.card_base class="p-10 mt-4">
            <.empty_state>
              {gettext("No messages visible yet")}
            </.empty_state>
          </.card_base>
        <% else %>
          <.live_component
            module={LantternWeb.MessageBoard.MessageBoardGridComponent}
            id="message-board-grid"
            sections={@sections}
            show_title={false}
            show_see_more={true}
          />
        <% end %>
      </.responsive_container>

      <.live_component
        :if={@card_message}
        module={CardMessageOverlayComponent}
        card_message={@card_message}
        id={"card-message-overlay-#{@card_message.id}"}
        on_cancel={JS.patch(~p"/school/message_board/view")}
        sticky_header={true}
        full_w={true}
        base_path={~p"/school/message_board/view"}
        current_user={@current_user}
        tz={@current_user.tz}
      />

      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="message-board-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter messages by class")}
        navigate={~p"/school/message_board/view"}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
    </Layouts.app_logged_in>
    """
  end
end
