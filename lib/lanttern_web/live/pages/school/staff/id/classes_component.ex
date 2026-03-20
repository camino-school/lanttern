defmodule LantternWeb.StaffMemberLive.ClassesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias LantternWeb.Schools.ClassSearchComponent
  alias LantternWeb.Schools.ClassStaffMemberFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="p-4">
        <div class="flex items-center justify-between gap-6 mb-6">
          <div>
            {ngettext("1 class", "%{count} classes", @smcr_length)}
          </div>
          <.button
            :if={@is_school_manager}
            type="button"
            phx-click={JS.push("link_class", target: @myself)}
          >
            {gettext("Link to class")}
          </.button>
        </div>
        <%= if @smcr_length == 0 do %>
          <.empty_state class="px-4 py-10">
            {gettext("Not linked to any class")}
          </.empty_state>
        <% else %>
          <.responsive_grid
            id="staff-member-classes"
            phx-update="stream"
          >
            <.card_base
              :for={{dom_id, smcr} <- @streams.smcr}
              id={dom_id}
              class="flex items-center gap-4 p-4"
            >
              <div class="min-w-0 flex-1">
                <.link
                  navigate={~p"/school/classes/#{smcr.class}/people"}
                  class="font-bold text-lg hover:text-ltrn-subtle"
                >
                  {smcr.class.name} ({smcr.class.cycle.name})
                </.link>
                <div :if={smcr.role} class="flex flex-wrap gap-1 mt-2">
                  <.badge>{smcr.role}</.badge>
                </div>
              </div>
              <div class="flex gap-2">
                <.button
                  type="button"
                  icon_name="hero-pencil-mini"
                  sr_text={gettext("Edit class link")}
                  rounded
                  size="sm"
                  theme="ghost"
                  phx-click={JS.push("edit", value: %{id: smcr.id}, target: @myself)}
                />
              </div>
            </.card_base>
          </.responsive_grid>
        <% end %>
      </.responsive_container>
      <.modal
        :if={@is_linking}
        id="link-staff-member-to-class-overlay"
        show
        on_cancel={JS.push("cancel_link_class", target: @myself)}
      >
        <:title>{gettext("Select class to link")}</:title>
        <.badge_button_picker
          on_select={
            &JS.push("link_to_class",
              value: %{"id" => &1},
              target: @myself
            )
          }
          items={@classes}
          selected_ids={[]}
          label_setter="class_with_cycle"
          current_user={@current_user}
        />
        <form class="mt-6">
          <.live_component
            module={ClassSearchComponent}
            id="link-to-class-search"
            school_id={@current_scope.school_id}
            exclude_ids={@linked_classes_ids}
            notify_component={@myself}
            label={gettext("Search all school classes")}
          />
        </form>
      </.modal>
      <.live_component
        :if={@class_staff_member}
        module={ClassStaffMemberFormOverlayComponent}
        id="edit-class-staff-member-overlay"
        class_staff_member={@class_staff_member}
        current_scope={@current_scope}
        on_cancel={JS.push("cancel_edit", target: @myself)}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:is_linking, false)
      |> assign(:class_staff_member, nil)
      |> assign(:linked_classes_ids, [])

    {:ok, socket}
  end

  @impl true
  def update(%{action: {ClassSearchComponent, {:selected, class}}}, socket) do
    {:ok, create_class_staff_member(socket, class)}
  end

  def update(%{action: {ClassStaffMemberFormOverlayComponent, {:updated, updated_csm}}}, socket) do
    socket =
      socket
      |> stream_insert(:smcr, updated_csm)
      |> assign(:class_staff_member, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Role updated successfully")})

    send(self(), {__MODULE__, {:role_updated, updated_csm}})
    {:ok, socket}
  end

  def update(%{action: {ClassStaffMemberFormOverlayComponent, {:deleted, csm}}}, socket) do
    socket =
      socket
      |> stream_delete(:smcr, csm)
      |> assign(:class_staff_member, nil)
      |> assign(:smcr_length, socket.assigns.smcr_length - 1)
      |> assign(
        :linked_classes_ids,
        Enum.reject(socket.assigns.linked_classes_ids, &(&1 == csm.class_id))
      )
      |> delegate_navigation(put_flash: {:info, gettext("Removed from class successfully")})

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_staff_member_classes()
    |> assign_classes()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_staff_member_classes(socket) do
    smcr =
      Schools.list_staff_member_classes(
        socket.assigns.current_scope,
        socket.assigns.staff_member
      )

    socket
    |> stream(:smcr, smcr, reset: true)
    |> assign(:smcr_length, length(smcr))
    |> assign(:linked_classes_ids, Enum.map(smcr, & &1.class_id))
  end

  defp assign_classes(socket) do
    classes =
      Schools.list_classes(
        schools_ids: [socket.assigns.current_scope.school_id],
        cycles_ids: [socket.assigns.current_user.current_profile.current_school_cycle.id]
      )
      |> Enum.reject(&(&1.id in socket.assigns.linked_classes_ids))

    assign(socket, :classes, classes)
  end

  # event handlers

  @impl true
  def handle_event("link_class", _params, socket) do
    {:noreply, assign(socket, :is_linking, true)}
  end

  def handle_event("cancel_link_class", _params, socket) do
    {:noreply, assign(socket, :is_linking, false)}
  end

  def handle_event("link_to_class", %{"id" => class_id}, socket) do
    class = Enum.find(socket.assigns.classes, &(&1.id == class_id))
    {:noreply, create_class_staff_member(socket, class)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    csmr =
      Schools.get_class_staff_member!(socket.assigns.current_scope, id, preloads: :class)

    {:noreply, assign(socket, :class_staff_member, csmr)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :class_staff_member, nil)}
  end

  defp create_class_staff_member(socket, class) do
    case Schools.create_class_staff_member(
           socket.assigns.current_scope,
           class,
           socket.assigns.staff_member
         ) do
      {:ok, _} ->
        socket
        |> assign(:is_linking, false)
        |> stream_staff_member_classes()
        |> delegate_navigation(put_flash: {:info, gettext("Class linked successfully")})

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          case changeset.errors do
            [{:staff_member_id, {msg, _}} | _] -> msg
            _ -> gettext("Failed to add to class")
          end

        delegate_navigation(socket, put_flash: {:error, error_message})
    end
  end
end
