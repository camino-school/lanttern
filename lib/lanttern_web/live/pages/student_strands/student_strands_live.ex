defmodule LantternWeb.StudentStrandsLive do
  @moduledoc """
  Student home live view
  """

  alias Lanttern.Identity.Profile
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Reporting
  alias Lanttern.Schools

  import LantternWeb.FiltersHelpers

  # shared components
  import LantternWeb.LearningContextComponents
  alias LantternWeb.Filters.InlineFiltersComponent
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    # check if user is guardian or student
    check_if_user_has_access(socket.assigns.current_user.current_profile)

    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_report_cards_cycles =
      Reporting.list_student_report_cards_cycles(student_id)

    socket =
      socket
      |> assign(:school, school)
      |> assign(:student_report_cards_cycles, student_report_cards_cycles)
      |> assign_user_filters([:cycles], socket.assigns.current_user)
      |> stream_student_strands()

    {:ok, socket}
  end

  defp check_if_user_has_access(%{type: profile_type} = %Profile{})
       when profile_type in ["student", "guardian"],
       do: nil

  defp check_if_user_has_access(_profile),
    do: raise(LantternWeb.NotFoundError)

  defp stream_student_strands(socket) do
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_strands =
      LearningContext.list_student_strands(
        student_id,
        cycles_ids: socket.assigns.selected_cycles_ids
      )

    has_student_strands = student_strands != []

    socket
    |> stream(:student_strands, student_strands, reset: true)
    |> assign(:has_student_strands, has_student_strands)
  end

  # info handlers

  @impl true
  def handle_info({InlineFiltersComponent, {:apply, cycles_ids}}, socket) do
    socket =
      socket
      |> assign(:selected_cycles_ids, cycles_ids)
      |> save_profile_filters(
        socket.assigns.current_user,
        [:cycles]
      )
      |> stream_student_strands()

    {:noreply, socket}
  end
end
