defmodule LantternWeb.StudentLive.AboutComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.StudentsCycleInfo.StudentCycleInfoFormComponent
  alias LantternWeb.StudentsCycleInfo.StudentCycleInfoHeaderComponent
  alias LantternWeb.StudentsCycleInfo.StudentCycleProfilePictureOverlayComponent
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10">
      <.live_component
        module={StudentCycleInfoHeaderComponent}
        id="student-cycle-info-header"
        selected_cycle_id={@student_info_selected_cycle_id}
        student={@student}
        student_cycle_info={@student_cycle_info}
        on_edit_profile_picture={JS.patch(~p"/school/students/#{@student}?edit_profile_picture=true")}
        on_change_cycle={
          fn cycle_id ->
            JS.push("change_cycle", value: %{"cycle_id" => cycle_id}, target: @myself)
          end
        }
      />
      <div class="flex items-start gap-20 mt-12">
        <div class="flex-1">
          <div class="pb-6 border-b-2 border-ltrn-light">
            <h4 class="font-display font-black text-lg"><%= gettext("School area") %></h4>
            <p class="flex items-center gap-2 mt-2">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Access to information in this area is restricted to school staff") %>
            </p>
          </div>
          <div class="py-10 border-b border-ltrn-light">
            <%= if @is_editing_student_school_info do %>
              <.live_component
                module={StudentCycleInfoFormComponent}
                id={"#{@student_cycle_info.id}-school-info-form"}
                student_cycle_info={@student_cycle_info}
                type="school"
                label={gettext("Add school area student info...")}
                current_profile_id={@current_user.current_profile_id}
                notify_component={@myself}
              />
            <% else %>
              <.empty_state_simple :if={!@student_cycle_info.school_info}>
                <%= gettext("No information about student in school area") %>
              </.empty_state_simple>
              <.markdown text={@student_cycle_info.school_info} />
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                class="mt-10"
                phx-click="edit_student_school_info"
                phx-target={@myself}
                disabled={@is_editing_shared_info}
              >
                <%= gettext("Edit information") %>
              </.action>
            <% end %>
          </div>
          <.live_component
            module={AttachmentAreaComponent}
            id="student-cycle-info-school-attachments"
            class="mt-10"
            student_cycle_info_id={@student_cycle_info.id}
            shared_with_student={false}
            title={gettext("School area attachments")}
            allow_editing
            current_user={@current_user}
          />
        </div>
        <div class="flex-1">
          <div class="pb-6 border-b-2 border-ltrn-student-lighter">
            <h4 class="font-display font-black text-lg text-ltrn-student-dark">
              <%= gettext("Student area") %>
            </h4>
            <p class="flex items-center gap-2 mt-2">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Information shared with student and guardians") %>
            </p>
          </div>
          <div class="py-10 border-b border-ltrn-student-lighter">
            <%= if @is_editing_shared_info do %>
              <.live_component
                module={StudentCycleInfoFormComponent}
                id={"#{@student_cycle_info.id}-student-info-form"}
                student_cycle_info={@student_cycle_info}
                type="student"
                label={gettext("Add student area info...")}
                current_profile_id={@current_user.current_profile_id}
                notify_component={@myself}
              />
            <% else %>
              <.empty_state_simple :if={!@student_cycle_info.shared_info}>
                <%= gettext("No information in student area") %>
              </.empty_state_simple>
              <.markdown text={@student_cycle_info.shared_info} />
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                class="mt-10"
                phx-click="edit_student_shared_info"
                phx-target={@myself}
                disabled={@is_editing_student_school_info}
              >
                <%= gettext("Edit information") %>
              </.action>
            <% end %>
          </div>
          <.live_component
            module={AttachmentAreaComponent}
            id="student-cycle-info-student-attachments"
            class="mt-10"
            student_cycle_info_id={@student_cycle_info.id}
            shared_with_student
            title={gettext("Student area attachments")}
            allow_editing
            current_user={@current_user}
          />
        </div>
      </div>
      <.live_component
        :if={@is_editing_profile_picture}
        module={StudentCycleProfilePictureOverlayComponent}
        id="profile_picture_modal"
        student_cycle_info={@student_cycle_info}
        student_name={@student.name}
        current_profile_id={@current_user.current_profile_id}
        notify_component={@myself}
        on_cancel={JS.patch(~p"/school/students/#{@student}")}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

  @impl true
  def update(%{action: {StudentCycleInfoFormComponent, {:cancel, "school"}}}, socket) do
    {:ok, assign(socket, :is_editing_student_school_info, false)}
  end

  def update(%{action: {StudentCycleInfoFormComponent, {:cancel, "student"}}}, socket) do
    {:ok, assign(socket, :is_editing_shared_info, false)}
  end

  def update(%{action: {StudentCycleInfoFormComponent, {:saved, student_cycle_info}}}, socket) do
    socket =
      socket
      |> assign(:student_cycle_info, student_cycle_info)
      |> assign(:is_editing_student_school_info, false)
      |> assign(:is_editing_shared_info, false)

    {:ok, socket}
  end

  def update(
        %{
          action:
            {StudentCycleProfilePictureOverlayComponent,
             {_uploaded_or_removed, student_cycle_info}}
        },
        socket
      ) do
    socket =
      socket
      |> assign(:student_cycle_info, student_cycle_info)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_is_editing_profile_picture()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign(:is_editing_student_school_info, false)
    |> assign(:is_editing_shared_info, false)
    |> assign_user_filters([:student_info])
    |> assign_student_cycle_info()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_student_cycle_info(socket) do
    student_cycle_info =
      StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(
        socket.assigns.student.id,
        socket.assigns.student_info_selected_cycle_id
      )
      |> case do
        nil ->
          # create student cycle info if it does not exist
          {:ok, info} =
            StudentsCycleInfo.create_student_cycle_info(
              %{
                school_id: socket.assigns.student.school_id,
                student_id: socket.assigns.student.id,
                cycle_id: socket.assigns.student_info_selected_cycle_id
              },
              log_profile_id: socket.assigns.current_user.current_profile_id
            )

          info

        student_cycle_info ->
          student_cycle_info
      end

    assign(socket, :student_cycle_info, student_cycle_info)
  end

  defp assign_is_editing_profile_picture(
         %{assigns: %{params: %{"edit_profile_picture" => "true"}}} = socket
       ),
       do: assign(socket, :is_editing_profile_picture, true)

  defp assign_is_editing_profile_picture(socket),
    do: assign(socket, :is_editing_profile_picture, false)

  # event handlers

  @impl true
  def handle_event("change_cycle", %{"cycle_id" => id}, socket) do
    socket =
      socket
      |> assign(:student_info_selected_cycle_id, id)
      |> save_profile_filters([:student_info])
      |> push_navigate(to: ~p"/school/students/#{socket.assigns.student}")

    {:noreply, socket}
  end

  def handle_event("edit_profile_picture", _params, socket),
    do: {:noreply, assign(socket, :is_editing_profile_picture, true)}

  def handle_event("cancel_edit_profile_picture", _params, socket),
    do: {:noreply, assign(socket, :is_editing_profile_picture, false)}

  def handle_event("edit_student_school_info", _params, socket),
    do: {:noreply, assign(socket, :is_editing_student_school_info, true)}

  def handle_event("edit_student_shared_info", _params, socket),
    do: {:noreply, assign(socket, :is_editing_shared_info, true)}
end
