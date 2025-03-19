defmodule LantternWeb.StudentILPLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.ILP
  alias Lanttern.Schools

  # shared components
  alias LantternWeb.ILP.StudentILPComponent
  alias LantternWeb.Schools.StudentHeaderComponent
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_student()
      |> assign_school()
      |> stream_student_ilps()

    {:ok, socket}
  end

  defp assign_student(socket) do
    student =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end
      |> Schools.get_student!()

    assign(socket, :student, student)
  end

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp stream_student_ilps(socket) do
    opts =
      [
        student_id: socket.assigns.student.id,
        cycle_id: socket.assigns.current_user.current_profile.current_school_cycle.id,
        preloads: [:cycle, :entries, template: [sections: :components]]
      ]

    opts =
      if socket.assigns.current_user.current_profile.type == "guardian" do
        [{:only_shared_with_guardians, true} | opts]
      else
        [{:only_shared_with_student, true} | opts]
      end

    student_ilps =
      ILP.list_students_ilps(opts)

    socket
    |> stream(:student_ilps, student_ilps)
    |> assign(:has_student_ilps, length(student_ilps) > 0)
  end
end
