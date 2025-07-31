defmodule LantternWeb.StudentHomeLiveV2 do
  @moduledoc """
  Student home live view
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
      |> assign_student()
      |> assign_school()
      |> assign_current_cycle()
      |> assign_student_cycle_info()
      |> assign_has_ilp()
      |> assign_card_sections_with_messages()
      |> assign(:card_message, nil)
      |> assign(:card_message_action, nil)

    {:ok, socket}
  end

  defp assign_student(socket) do
    student =
      socket.assigns.current_user.current_profile.student_id
      |> Schools.get_student!()

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
    has_ilp =
      ILP.student_has_ilp_for_cycle?(
        socket.assigns.student.id,
        socket.assigns.current_cycle.id,
        :shared_with_student
      )

    assign(socket, :has_ilp, has_ilp)
  end

  defp assign_card_sections_with_messages(socket) do
    card_sections = MessageBoard.list_card_sections()

    assign(socket, :card_sections, card_sections)
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
    card_message = MessageBoard.get_card_message!(message_id)
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
          socket
          |> push_navigate(to: ~p"/student")
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("card_lookout", %{"id" => id}, socket) do
    socket =
      socket
      |> push_navigate(to: ~p"/student_v2?message=#{id}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.responsive_container class="pt-6 sm:pt-10">
      <.page_title_with_menu><%= gettext("Welcome!") %></.page_title_with_menu>
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
              <%= gettext("Explore strands") %>
            </div>
          </.link>
        </.card_base>
        <.card_base>
          <.link navigate={~p"/student_report_cards"} class="block p-6 hover:text-ltrn-subtle">
            <.icon name="hero-map-pin" class="w-8 h-8 text-ltrn-subtle" />
            <div class="mt-4 font-display font-black text-xl">
              <%= gettext("View report cards") %>
            </div>
          </.link>
        </.card_base>
        <.card_base :if={@has_ilp}>
          <.link navigate={~p"/student_ilp"} class="block p-6 hover:text-ltrn-subtle">
            <.icon name="hero-check-badge" class="w-8 h-8 text-ltrn-subtle" />
            <div class="mt-4 font-display font-black text-xl">
              <%= gettext("Read the ILP") %>
            </div>
          </.link>
        </.card_base>
      </div>
    </.responsive_container>

    <.responsive_container class="mt-16">
      <div class="space-y-8">
        <div>
          <h2 class="text-2xl font-bold text-gray-800 mb-2">
            <%= gettext("Message board") %>
          </h2>
        </div>

        <%= for section <- @card_sections do %>
          <div class="space-y-4">
            <div>
              <h3 class="text-xl font-semibold text-gray-700 mb-1">
                <%= section.name %>
              </h3>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <%= for message <- section.messages do %>
                <.render_card_message message={message} />
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
        <%= gettext("Additional %{cycle} information", cycle: @current_cycle.name) %>
      </h3>
      <.markdown
        :if={@student_cycle_info.shared_info}
        text={@student_cycle_info.shared_info}
        class="mt-10"
      />
      <.live_component
        :if={@student_cycle_info.has_attachments}
        module={AttachmentAreaComponent}
        id="student-cycle-info-family-attachments"
        class="mt-10"
        student_cycle_info_id={@student_cycle_info.id}
        shared_with_student
        title={gettext("%{cycle} attachments", cycle: @current_cycle.name)}
      />
    </.responsive_container>
    <.school_branding_footer school={@school} class="mt-20" />

    <.live_component
      :if={@card_message}
      module={CardMessageOverlayComponent}
      card_message={@card_message}
      id={"card-message-overlay-#{@card_message.id}"}
      on_cancel={JS.patch(~p"/student_v2/")}
      base_path={~p"/student_v2"}
      current_user={@current_user}
      tz={@current_user.tz}
    />
    """
  end
end
