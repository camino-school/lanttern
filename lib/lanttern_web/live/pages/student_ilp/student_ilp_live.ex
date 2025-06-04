defmodule LantternWeb.StudentILPLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  import LantternWeb.SchoolsComponents

  alias Lanttern.ILP
  alias Lanttern.Schools

  # shared components
  alias LantternWeb.ILP.ILPCommentFormOverlayComponent
  alias LantternWeb.ILP.StudentILPComponent
  alias LantternWeb.Schools.StudentHeaderComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_student()
      |> assign_school()
      |> stream_student_ilps()
      |> assign_base_path()
      |> assign(:ilp_comment, nil)
      |> assign(:ilp_comment_title, nil)
      |> assign(:ilp_comment_action, nil)
      |> assign(:ilp_comments, [])

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

    student_ilps = ILP.list_students_ilps(opts)

    socket
    |> assign(:student_ilp, List.first(student_ilps))
    |> stream(:student_ilps, student_ilps)
    |> assign(:has_student_ilps, length(student_ilps) > 0)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_ilp_comment()

    {:noreply, socket}
  end

  defp assign_ilp_comment(%{assigns: %{params: %{"comment" => "new"}}} = socket) do
    socket
    |> assign(:ilp_comment, %ILP.ILPComment{})
    |> assign(:ilp_comment_title, gettext("New Comment"))
    |> assign(:ilp_comment_action, :new)
  end

  defp assign_ilp_comment(%{assigns: %{params: %{"comment_id" => id}}} = socket) do
    socket
    |> assign(:ilp_comment, ILP.get_ilp_comment(id))
    |> assign(:ilp_comment_title, gettext("Edit Comment"))
    |> assign(:ilp_comment_action, :edit)
  end

  defp assign_ilp_comment(socket), do: assign(socket, :ilp_comment, nil)

  defp assign_base_path(socket) do
    base_path = ~p"/student_ilp"

    assign(socket, :base_path, base_path)
  end

  @impl true
  def handle_info({ILPCommentFormOverlayComponent, {:deleted, _data}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Comment deleted successfully"))
      |> push_navigate(to: socket.assigns.base_path)

    {:noreply, socket}
  end

  def handle_info({ILPCommentFormOverlayComponent, {:created, _data}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Comment created successfully"))
      |> push_navigate(to: socket.assigns.base_path)

    {:noreply, socket}
  end

  def handle_info({ILPCommentFormOverlayComponent, {:updated, _data}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Comment updated successfully"))
      |> push_navigate(to: socket.assigns.base_path)

    {:noreply, socket}
  end
end
