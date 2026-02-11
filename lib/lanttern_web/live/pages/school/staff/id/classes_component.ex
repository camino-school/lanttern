defmodule LantternWeb.StaffMemberLive.ClassesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias LantternWeb.Schools.ClassSearchComponent

  # shared components
  import LantternWeb.SchoolsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <div class="py-6 px-4 lg:px-0">
        <h3 class="font-display font-bold text-2xl">
          {gettext("Classes")}
        </h3>
      </div>
      <div class="flex justify-between gap-6 p-4 bg-white rounded-t">
        <div>
          {ngettext("1 class", "%{count} classes", @classes_length)}
        </div>
        <.action
          :if={@is_school_manager}
          type="button"
          icon_name="hero-plus-circle-mini"
          phx-click="show_class_search"
          phx-target={@myself}
        >
          {gettext("Add to class")}
        </.action>
      </div>
      <%= if @classes_length == 0 do %>
        <.empty_state class="px-4 py-10 bg-white">
          {gettext("Not linked to any class")}
        </.empty_state>
      <% else %>
        <.fluid_grid
          id="staff-classes"
          phx-update="stream"
          phx-hook={if @is_school_manager, do: "Sortable", else: nil}
          is_full_width
          class="p-4 bg-white"
        >
          <.class_card_for_staff
            :for={{dom_id, csm} <- @streams.classes}
            id={dom_id}
            data-id={csm.id}
            class_staff_member={csm}
            show_actions={@is_school_manager}
            on_edit_role={JS.push("edit_role", value: %{id: csm.id}, target: @myself)}
            on_remove={JS.push("remove", value: %{id: csm.id}, target: @myself)}
            sortable={@is_school_manager}
          />
        </.fluid_grid>
      <% end %>
      <.live_component
        :if={@show_class_search}
        module={ClassSearchComponent}
        id="class-search"
        school_id={@staff_member.school_id}
        notify_component={@myself}
      />
      <.modal
        :if={@editing_role_for}
        id="edit-role-modal"
        show
        on_cancel={JS.push("cancel_edit_role", target: @myself)}
      >
        <.header>
          {gettext("Edit role in class")}
        </.header>
        <.form for={@role_form} phx-submit="update_role" phx-target={@myself}>
          <.input
            field={@role_form[:role]}
            label={gettext("Role in class")}
            placeholder={gettext("e.g., Lead Teacher, Assistant, etc.")}
            phx-debounce="blur"
          />
          <.input type="hidden" field={@role_form[:id]} />
          <div class="flex gap-2 mt-6 justify-end">
            <.button type="button" phx-click="cancel_edit_role" phx-target={@myself} theme="ghost">
              {gettext("Cancel")}
            </.button>
            <.button type="submit">{gettext("Save")}</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:initialized, false)
     |> assign(:show_class_search, false)
     |> assign(:editing_role_for, nil)}
  end

  @impl true
  def update(%{action: {ClassSearchComponent, {:selected, class}}}, socket) do
    case Schools.add_staff_member_to_class(%{
           class_id: class.id,
           staff_member_id: socket.assigns.staff_member.id
         }) do
      {:ok, _} ->
        socket =
          socket
          |> assign(:show_class_search, false)
          |> stream_staff_classes()
          |> put_flash(:info, gettext("Added to class successfully"))

        send(self(), {__MODULE__, {:class_added, class}})
        {:ok, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          case changeset.errors do
            [{:staff_member_id, {msg, _}} | _] -> msg
            _ -> gettext("Failed to add to class")
          end

        {:ok, put_flash(socket, :error, error_message)}
    end
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
    |> stream_staff_classes()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_staff_classes(socket) do
    classes =
      Schools.list_staff_member_classes(
        socket.assigns.staff_member.id
      )

    socket
    |> stream(:classes, classes, reset: true)
    |> assign(:classes_length, length(classes))
  end

  # event handlers

  @impl true
  def handle_event("show_class_search", _params, socket) do
    {:noreply, assign(socket, :show_class_search, true)}
  end

  def handle_event("edit_role", %{"id" => id}, socket) do
    csm = Schools.get_class_staff_member!(id, preloads: :class)

    form =
      csm
      |> Ecto.Changeset.change(%{})
      |> to_form()

    socket =
      socket
      |> assign(:editing_role_for, csm.id)
      |> assign(:role_form, form)

    {:noreply, socket}
  end

  def handle_event("cancel_edit_role", _params, socket) do
    {:noreply, assign(socket, :editing_role_for, nil)}
  end

  def handle_event("update_role", %{"class_staff_member" => params}, socket) do
    csm = Schools.get_class_staff_member!(socket.assigns.editing_role_for)

    case Schools.update_class_staff_member(csm, params) do
      {:ok, updated_csm} ->
        # Reload with preloads
        updated_csm = Schools.get_class_staff_member!(updated_csm.id, preloads: [class: [:school, :cycle]])

        socket =
          socket
          |> stream_insert(:classes, updated_csm)
          |> assign(:editing_role_for, nil)
          |> put_flash(:info, gettext("Role updated successfully"))

        send(self(), {__MODULE__, {:role_updated, updated_csm}})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :role_form, to_form(changeset))}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    csm = Schools.get_class_staff_member!(id)

    case Schools.remove_staff_member_from_class(csm) do
      {:ok, _} ->
        socket =
          socket
          |> stream_delete(:classes, csm)
          |> assign(:classes_length, socket.assigns.classes_length - 1)
          |> put_flash(:info, gettext("Removed from class successfully"))

        send(self(), {__MODULE__, {:class_removed, csm}})
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove from class"))}
    end
  end

  def handle_event("reorder", %{"ids" => ids}, socket) do
    case Schools.update_staff_member_classes_positions(socket.assigns.staff_member.id, ids) do
      :ok ->
        {:noreply, put_flash(socket, :info, gettext("Classes reordered"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to reorder classes"))}
    end
  end
end
