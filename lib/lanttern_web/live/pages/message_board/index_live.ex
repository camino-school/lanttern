defmodule LantternWeb.MessageBoard.IndexLive do
  use LantternWeb, :live_view

  import LantternWeb.CoreComponents
  import LantternWeb.MessageBoard.Components
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

  alias Lanttern.MessageBoardV2, as: MessageBoard
  alias Lanttern.MessageBoard.MessageV2, as: Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Schools.Cycle

  alias LantternWeb.MessageBoard.MessageFormOverlayComponentV2, as: MessageFormOverlayComponent

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
      |> assign(:page_title, gettext("Message board"))

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
        |> push_patch(to: ~p"/school/message_board_v2")
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
        |> push_patch(to: ~p"/school/message_board_v2")
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
        |> push_patch(to: ~p"/school/message_board_v2")
        |> assign_sections()
        |> assign(:form_action, nil)
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete section"))}
    end
  end

  def handle_event("sortable_update", %{"oldIndex" => old, "newIndex" => new}, socket) do
    messages = socket.assigns.section.messages
    {changed_id, rest} = List.pop_at(messages, old)
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
    |> push_patch(to: ~p"/school/message_board_v2")
    |> assign_sections()
    |> then(&{:noreply, &1})
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
    section = MessageBoard.get_section_with_ordered_messages!(id)
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
end
