defmodule LantternWeb.Schools.ClassFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Class` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  alias Lanttern.Taxonomy

  require Logger

  # shared
  alias LantternWeb.Schools.StaffMemberSearchComponent
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id="class-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            {gettext("Oops, something went wrong! Please check the errors below.")}
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <div class="mb-6">
            <.label>{gettext("Cycle")}</.label>
            <.badge_button_picker
              id="class-cycle-select"
              on_select={
                &(JS.push("select_cycle", value: %{"id" => &1}, target: @myself)
                  |> JS.dispatch("change", to: "#class-form"))
              }
              items={@cycles}
              selected_ids={[@selected_cycle_id]}
            />
            <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:cycle_id].errors}>{msg}</.error>
            </div>
          </div>
          <div class="mb-6">
            <.label>{gettext("Year")}</.label>
            <.badge_button_picker
              id="class-year-select"
              on_select={
                &(JS.push("select_year", value: %{"id" => &1}, target: @myself)
                  |> JS.dispatch("change", to: "#class-form"))
              }
              items={@years}
              selected_ids={@selected_years_ids}
            />
            <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:years_ids].errors}>{msg}</.error>
            </div>
          </div>
          <div class="mb-6">
            <.live_component
              module={StaffMemberSearchComponent}
              id="staff-member-search"
              notify_component={@myself}
              label={gettext("Staff members in this class")}
              refocus_on_select="true"
              school_id={@class.school_id}
              exclude_ids={Enum.map(@staff_members, & &1.id)}
            />
            <%= if @staff_members != [] do %>
              <ul
                class="mt-4 text-sm leading-relaxed"
                id="staff-members-list"
                data-group-id="staff-members-list"
                data-sortable-event="sortable_update"
                data-sortable-handle=".sortable-handle"
                phx-hook="Sortable"
                phx-target={@myself}
              >
                <li
                  :for={staff_member <- @staff_members}
                  id={"selected-staff-member-#{staff_member.id}"}
                  data-id={staff_member.id}
                  class="flex items-center gap-2"
                >
                  <div class="shrink-0 flex text-ltrn-subtle hover:text-ltrn-dark hover:cursor-move sortable-handle">
                    <.icon name="hero-ellipsis-vertical-mini" class="w-5 h-5" />
                    <.icon name="hero-ellipsis-vertical-mini" class="w-5 h-5 -ml-3" />
                  </div>
                  {staff_member.name}
                  <.button
                    type="button"
                    icon_name="hero-x-mark-mini"
                    class="align-middle"
                    size="sm"
                    theme="ghost"
                    rounded
                    phx-click={
                      JS.push("remove_staff_member",
                        value: %{"id" => staff_member.id},
                        target: @myself
                      )
                    }
                  />
                </li>
              </ul>
            <% else %>
              <.empty_state_simple class="mt-4">
                {gettext("No staff members added to this class")}
              </.empty_state_simple>
            <% end %>
          </div>
          <div class="mb-6">
            <.live_component
              module={StudentSearchComponent}
              id="student-search"
              notify_component={@myself}
              label={gettext("Students in this class")}
              refocus_on_select="true"
              school_id={@class.school_id}
              exclude_ids={Enum.map(@students, & &1.id)}
            />
            <%= if @students != [] do %>
              <ol
                class="mt-4 text-sm leading-relaxed list-decimal list-inside"
                id="students-list"
                data-group-id="students-list"
                data-sortable-event="sortable_update"
                data-sortable-handle=".cursor-move"
                phx-hook="Sortable"
                phx-target={@myself}
              >
                <li
                  :for={student <- @students}
                  id={"selected-student-#{student.id}"}
                  data-id={student.id}
                  class="cursor-move"
                >
                  {student.name}
                  <.button
                    type="button"
                    icon_name="hero-x-mark-mini"
                    class="align-middle"
                    size="sm"
                    theme="ghost"
                    rounded
                    phx-click={
                      JS.push("remove_student", value: %{"id" => student.id}, target: @myself)
                    }
                  />
                </li>
              </ol>
            <% else %>
              <.empty_state_simple class="mt-4">
                {gettext("No students added to this class")}
              </.empty_state_simple>
            <% end %>
          </div>
        </.form>
        <:actions_left :if={@class.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.button>
        </:actions_left>
        <:actions>
          <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
            {gettext("Cancel")}
          </.button>
          <.button type="submit" form="class-form">
            {gettext("Save")}
          </.button>
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
  def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
    students =
      [student | socket.assigns.students]
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    {:ok, assign(socket, :students, students)}
  end

  def update(%{action: {StaffMemberSearchComponent, {:selected, staff_member}}}, socket) do
    # Add new staff member to the end of the list, maintaining current order
    staff_members =
      (socket.assigns.staff_members ++ [staff_member])
      |> Enum.uniq_by(& &1.id)

    {:ok, assign(socket, :staff_members, staff_members)}
  end

  def update(%{class: %Class{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_cycles()
      |> assign_years()
      |> assign_students()
      |> assign_staff_members()
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_form(socket) do
    class = socket.assigns.class
    changeset = Schools.change_class(class)

    selected_years_ids = Enum.map(class.years, & &1.id)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_cycle_id, class.cycle_id)
    |> assign(:selected_years_ids, selected_years_ids)
  end

  defp assign_cycles(%{assigns: %{initialized: false}} = socket) do
    school_id = socket.assigns.class.school_id
    cycles = Schools.list_cycles(schools_ids: [school_id], parent_cycles_only: true)
    assign(socket, :cycles, cycles)
  end

  defp assign_cycles(socket), do: socket

  defp assign_years(%{assigns: %{initialized: false}} = socket) do
    years = Taxonomy.list_years()
    assign(socket, :years, years)
  end

  defp assign_years(socket), do: socket

  defp assign_students(%{assigns: %{initialized: false}} = socket) do
    students =
      case socket.assigns.class.id do
        nil -> []
        class_id -> Schools.list_students(class_id: class_id)
      end

    assign(socket, :students, students)
  end

  defp assign_students(socket), do: socket

  defp assign_staff_members(%{assigns: %{initialized: false}} = socket) do
    staff_members =
      case socket.assigns.class.id do
        nil -> []
        class_id -> list_staff_members_for_class(class_id)
      end

    assign(socket, :staff_members, staff_members)
  end

  defp assign_staff_members(socket), do: socket

  defp list_staff_members_for_class(class_id) do
    staff_with_position = Schools.list_class_staff_members(class_id)

    if staff_with_position == [] do
      []
    else
      staff_member_ids = Enum.map(staff_with_position, & &1.id)

      staff_member_ids
      |> then(&Schools.list_staff_members(staff_members_ids: &1, only_active: true))
      |> Enum.sort_by(&Enum.find_index(staff_member_ids, fn id -> id == &1.id end))
    end
  end

  # event handlers

  @impl true
  def handle_event("remove_student", %{"id" => id}, socket) do
    students =
      socket.assigns.students
      |> Enum.reject(&(&1.id == id))

    {:noreply, assign(socket, :students, students)}
  end

  def handle_event("remove_staff_member", %{"id" => id}, socket) do
    staff_members =
      socket.assigns.staff_members
      |> Enum.reject(&(&1.id == id))

    {:noreply, assign(socket, :staff_members, staff_members)}
  end

  def handle_event("sortable_update", %{"from" => %{"groupId" => "students-list"}, "oldIndex" => old_index, "newIndex" => new_index}, socket) do
    # Reorder students based on the drag and drop
    students =
      socket.assigns.students
      |> List.delete_at(old_index)
      |> List.insert_at(new_index, Enum.at(socket.assigns.students, old_index))

    {:noreply, assign(socket, :students, students)}
  end

  def handle_event("sortable_update", %{"from" => %{"groupId" => "staff-members-list"}, "oldIndex" => old_index, "newIndex" => new_index}, socket) do
    # Reorder staff members based on the drag and drop
    staff_members =
      socket.assigns.staff_members
      |> List.delete_at(old_index)
      |> List.insert_at(new_index, Enum.at(socket.assigns.staff_members, old_index))

    {:noreply, assign(socket, :staff_members, staff_members)}
  end

  def handle_event("select_cycle", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:selected_cycle_id, id)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_year", %{"id" => id}, socket) do
    selected_years_ids =
      if id in socket.assigns.selected_years_ids,
        do: Enum.reject(socket.assigns.selected_years_ids, &(&1 == id)),
        else: [id | socket.assigns.selected_years_ids]

    socket =
      socket
      |> assign(:selected_years_ids, selected_years_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("validate", %{"class" => class_params}, socket),
    do: {:noreply, assign_validated_form(socket, class_params)}

  def handle_event("save", %{"class" => class_params}, socket) do
    class_params =
      inject_extra_params(socket, class_params)

    save_class(socket, socket.assigns.class.id, class_params)
  end

  def handle_event("delete", _, socket) do
    Schools.delete_class(socket.assigns.class)
    |> case do
      {:ok, class} ->
        notify(__MODULE__, {:deleted, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    # Preload associations before creating changeset
    # This is required for put_assoc to work
    class =
      socket.assigns.class
      |> Lanttern.Repo.preload([:students, :years, :staff_members])

    changeset =
      class
      |> Schools.change_class(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.class.school_id)
    |> Map.put("cycle_id", socket.assigns.selected_cycle_id)
    |> Map.put("years_ids", socket.assigns.selected_years_ids)
    |> Map.put("students_ids", socket.assigns.students |> Enum.map(& &1.id))
    |> Map.put("staff_members_ids", socket.assigns.staff_members |> Enum.map(& &1.id))
  end

  defp save_class(socket, nil, class_params) do
    Schools.create_class(class_params)
    |> case do
      {:ok, class} ->
        # Update positions after creating
        update_positions_after_save(class.id, socket)
        notify(__MODULE__, {:created, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_class(socket, _id, class_params) do
    Schools.update_class(
      socket.assigns.class,
      class_params
    )
    |> case do
      {:ok, class} ->
        # Update positions after updating
        update_positions_after_save(class.id, socket)
        notify(__MODULE__, {:updated, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp update_positions_after_save(class_id, socket) do
    # Update staff members positions based on order
    # Use class_staff_member_id for existing staff members, otherwise use staff_member_id
    # The update_class_staff_members_positions function will use staff_member_id to find the records
    staff_member_ids = Enum.map(socket.assigns.staff_members, & &1.id)

    case Schools.update_class_staff_members_positions(class_id, staff_member_ids) do
      :ok ->
        Logger.debug("Successfully updated staff member positions")
        :ok

      {:error, reason} ->
        Logger.error("Failed to update staff member positions: #{inspect(reason)}")
        :ok
    end

    # Update students positions if there's a function for it
    # (similar to staff members)
    :ok
  end
end
