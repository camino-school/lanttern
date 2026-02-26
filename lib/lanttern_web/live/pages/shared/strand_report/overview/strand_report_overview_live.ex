defmodule LantternWeb.StrandReportOverviewLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Scope
  alias Lanttern.Reporting
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_student_report_card(params)
      # check if user can view the strand report
      |> check_if_user_has_access()
      |> assign_strand_report(params)
      |> assign_base_path_and_navigation_context(params)

    {:ok, socket}
  end

  defp assign_student_report_card(socket, params) do
    %{"strand_report_id" => strand_report_id} = params

    student_report_card =
      case params do
        %{"student_report_card_id" => id} ->
          Reporting.get_student_report_card!(id,
            preloads: [
              :student,
              report_card: :school_cycle
            ]
          )

        _ ->
          # don't need to worry with other profile types
          # (handled by :ensure_authenticated_student_or_guardian in router)
          Reporting.get_student_report_card_by_student_and_strand_report(
            socket.assigns.current_scope.student_id,
            strand_report_id,
            preloads: [
              :student,
              report_card: :school_cycle
            ]
          )
      end

    assign(socket, :student_report_card, student_report_card)
  end

  defp check_if_user_has_access(%{assigns: %{student_report_card: nil}} = _socket),
    do: raise(LantternWeb.NotFoundError)

  defp check_if_user_has_access(socket) do
    %{current_scope: current_scope, student_report_card: student_report_card} = socket.assigns
    # check if user can view the student strand report
    # guardian and students can only view their own reports
    # staff members can view only reports from their school

    report_card_student_id = student_report_card.student_id
    report_card_student_school_id = student_report_card.student.school_id

    case current_scope do
      %Scope{profile_type: "guardian", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Scope{profile_type: "student", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Scope{profile_type: "staff", school_id: school_id}
      when school_id == report_card_student_school_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end

    socket
  end

  defp assign_strand_report(socket, params) do
    %{"strand_report_id" => strand_report_id} = params
    student_report_card = socket.assigns.student_report_card

    strand_report =
      Reporting.get_strand_report!(strand_report_id,
        preloads: [strand: [:subjects, :years]],
        check_if_has_moments: true
      )

    cover_image_url =
      object_url_to_render_url(
        strand_report.cover_image_url || strand_report.strand.cover_image_url,
        width: 1280,
        height: 640
      )

    page_title =
      "#{strand_report.strand.name} • #{student_report_card.student.name} • #{student_report_card.report_card.name}"

    socket
    |> assign(:strand_report, strand_report)
    |> assign(:cover_image_url, cover_image_url)
    |> assign(:page_title, page_title)
  end

  defp assign_base_path_and_navigation_context(socket, params) do
    strand_report_id = socket.assigns.strand_report.id

    {base_path, navigation_context} =
      case Map.get(params, "student_report_card_id") do
        nil ->
          {"/strand_report/#{strand_report_id}", :strand_report}

        report_card_id ->
          {"/student_report_cards/#{report_card_id}/strand_report/#{strand_report_id}",
           :report_card}
      end

    socket
    |> assign(:base_path, base_path)
    |> assign(:navigation_context, navigation_context)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)

    {:noreply, socket}
  end
end
