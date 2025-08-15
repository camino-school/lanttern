defmodule LantternWeb.HomeLive do
  @moduledoc """
  Home live view for both students and guardians
  """

  use LantternWeb, :live_view

  import LantternWeb.SchoolsComponents

  alias Lanttern.ILP
  alias Lanttern.MessageBoard
  alias Lanttern.Personalization
  alias Lanttern.Schools
  alias Lanttern.StudentsCycleInfo

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.MessageBoard.CardMessageOverlayComponent
  alias LantternWeb.Schools.StudentHeaderComponent

  import LantternWeb.MessageBoard.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_profile_type()
      |> assign_student()
      |> assign_school()
      |> assign_current_cycle()
      |> assign_student_cycle_info()
      |> assign_has_ilp()
      |> assign_messages_with_section()
      |> assign(:card_message, nil)
      |> assign(:card_message_action, nil)

    {:ok, socket}
  end

  defp assign_profile_type(socket) do
    type = socket.assigns.current_user.current_profile.type
    assign(socket, :profile_type, type)
  end

  defp assign_student(socket) do
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student", student_id: id} -> id
        %{type: "guardian", guardian_of_student_id: id} -> id
      end

    student = Schools.get_student!(student_id)
    assign(socket, :student, student)
  end

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp assign_current_cycle(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle
    assign(socket, :current_cycle, current_cycle)
  end

  defp assign_student_cycle_info(socket) do
    student_cycle_info =
      StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(
        socket.assigns.student.id,
        socket.assigns.current_cycle.id,
        check_attachments_for: :student
      )
      |> case do
        nil ->
          {:ok, info} =
            StudentsCycleInfo.create_student_cycle_info(
              %{
                school_id: socket.assigns.student.school_id,
                student_id: socket.assigns.student.id,
                cycle_id: socket.assigns.current_cycle.id
              },
              log_profile_id: socket.assigns.current_user.current_profile_id
            )

          info

        student_cycle_info ->
          student_cycle_info
      end

    assign(socket, :student_cycle_info, student_cycle_info)
  end

  defp assign_has_ilp(socket) do
    permission =
      case socket.assigns.profile_type do
        "student" -> :shared_with_student
        "guardian" -> :shared_with_guardians
        _ -> :shared_with_student
      end

    has_ilp =
      ILP.student_has_ilp_for_cycle?(
        socket.assigns.student.id,
        socket.assigns.current_cycle.id,
        permission
      )

    assign(socket, :has_ilp, has_ilp)
  end

  defp assign_messages_with_section(socket) do
    school_id = socket.assigns.school.id
    student_id = socket.assigns.student.id
    sections = MessageBoard.list_sections_for_students(student_id, school_id)
    assign(socket, :sections, sections)
  end

  @impl true
  def handle_info({CardMessageOverlayComponent, {_action, _data}}, socket) do
    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)

    {:noreply, socket}
  end

  @impl true
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
  def handle_event("change_cycle", %{"cycle_id" => cycle_id}, socket) do
    socket =
      Personalization.set_profile_settings(
        socket.assigns.current_user.current_profile.id,
        %{current_school_cycle_id: cycle_id}
      )
      |> case do
        {:ok, _profile_setting} ->
          path =
            case socket.assigns.profile_type do
              "student" -> ~p"/student"
              "guardian" -> ~p"/guardian"
              _ -> ~p"/student"
            end

          socket
          |> push_navigate(to: path)
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("card_lookout", %{"id" => id}, socket) do
    base_path =
      case socket.assigns.profile_type do
        "guardian" -> "/guardian"
        _ -> "/student"
      end

    socket =
      socket
      |> push_navigate(to: "#{base_path}?message=#{id}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_logged_in flash={@flash} current_user={@current_user} current_path={@current_path}>
      <.responsive_container class="pt-6 sm:pt-10">
        <.page_title_with_menu>
          {gettext("Welcome!")}
        </.page_title_with_menu>
        <.live_component
          module={StudentHeaderComponent}
          id="student-cycle-info-header"
          cycle_id={@current_user.current_profile.current_school_cycle.id}
          student_id={@student.id}
          class="mt-20"
          cycle_tooltip={gettext("Looking for a different cycle? You can change it in the menu.")}
        />
        <div class={[
          "grid grid-cols-1 sm:grid-cols-2 gap-6 mt-10",
          if(@has_ilp, do: "md:grid-cols-3")
        ]}>
          <.card_base>
            <.link navigate={~p"/student_strands"} class="block p-6 hover:text-ltrn-subtle">
              <.icon name="hero-map" class="w-8 h-8 text-ltrn-subtle" />
              <div class="mt-4 font-display font-black text-xl">
                {gettext("Explore strands")}
              </div>
            </.link>
          </.card_base>
          <.card_base>
            <.link navigate={~p"/student_report_cards"} class="block p-6 hover:text-ltrn-subtle">
              <.icon name="hero-map-pin" class="w-8 h-8 text-ltrn-subtle" />
              <div class="mt-4 font-display font-black text-xl">
                {gettext("View report cards")}
              </div>
            </.link>
          </.card_base>
          <.card_base :if={@has_ilp}>
            <.link navigate={~p"/student_ilp"} class="block p-6 hover:text-ltrn-subtle">
              <.icon name="hero-check-badge" class="w-8 h-8 text-ltrn-subtle" />
              <div class="mt-4 font-display font-black text-xl">
                {gettext("Read the ILP")}
              </div>
            </.link>
          </.card_base>
        </div>
      </.responsive_container>

      <.responsive_container class="mt-16">
        <div class="space-y-8">
          <div>
            <h2 class="text-2xl font-bold text-gray-800 mb-2">
              {gettext("Message board")}
            </h2>
          </div>

          <%= for section <- @sections do %>
            <div class="space-y-4">
              <div>
                <h3 class="text-xl font-semibold text-gray-700 mb-1">
                  {section.name}
                </h3>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <%= for message <- section.messages do %>
                  <.message_card message={message} />
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </.responsive_container>

      <.responsive_container
        :if={@student_cycle_info.shared_info || @student_cycle_info.has_attachments}
        class="mt-20"
      >
        <h3 class="font-display font-black text-xl">
          {gettext("Additional %{cycle} information", cycle: @current_cycle.name)}
        </h3>
        <.markdown
          :if={@student_cycle_info.shared_info}
          text={@student_cycle_info.shared_info}
          class="mt-10"
        />
        <%= if @student_cycle_info.has_attachments do %>
          <%= if @profile_type == "guardian" do %>
            <.live_component
              module={AttachmentAreaComponent}
              id="student-cycle-info-family-attachments"
              class="mt-10"
              student_cycle_info_id={@student_cycle_info.id}
              shared_with_guardian={true}
              title={gettext("%{cycle} attachments", cycle: @current_cycle.name)}
            />
          <% else %>
            <.live_component
              module={AttachmentAreaComponent}
              id="student-cycle-info-family-attachments"
              class="mt-10"
              student_cycle_info_id={@student_cycle_info.id}
              shared_with_student={true}
              title={gettext("%{cycle} attachments", cycle: @current_cycle.name)}
            />
          <% end %>
        <% end %>
      </.responsive_container>
      <.school_branding_footer school={@school} class="mt-20" />
    </Layouts.app_logged_in>

    <.live_component
      :if={@card_message}
      module={CardMessageOverlayComponent}
      card_message={@card_message}
      id={"card-message-overlay-#{@card_message.id}"}
      on_cancel={JS.patch(if @profile_type == "guardian", do: ~p"/guardian", else: ~p"/student")}
      base_path={if @profile_type == "guardian", do: ~p"/guardian", else: ~p"/student"}
      current_user={@current_user}
      tz={@current_user.tz}
    />
    """
  end
end
