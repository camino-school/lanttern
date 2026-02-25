defmodule LantternWeb.StrandReportOverviewLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Profile
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
      |> assign_allow_access()

    {:ok, socket}
  end

  defp assign_student_report_card(socket, params) do
    %{"strand_report_id" => strand_report_id} = params

    # don't need to worry with other profile types
    # (handled by :ensure_authenticated_student_or_guardian in router)
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_report_card =
      Reporting.get_student_report_card_by_student_and_strand_report(student_id, strand_report_id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    assign(socket, :student_report_card, student_report_card)
  end

  defp check_if_user_has_access(%{assigns: %{student_report_card: nil}} = _socket),
    do: raise(LantternWeb.NotFoundError)

  defp check_if_user_has_access(socket) do
    %{current_user: current_user, student_report_card: student_report_card} = socket.assigns
    # check if user can view the student strand report
    # guardian and students can only view their own reports

    report_card_student_id = student_report_card.student_id

    case current_user.current_profile do
      %Profile{type: "guardian", guardian_of_student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Profile{type: "student", student_id: student_id}
      when student_id == report_card_student_id ->
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

  defp assign_allow_access(socket) do
    allow_access =
      case {socket.assigns.current_user.current_profile.type, socket.assigns.student_report_card} do
        {"student", %{allow_student_access: true}} -> true
        {"guardian", %{allow_guardian_access: true}} -> true
        _ -> false
      end

    assign(socket, :allow_access, allow_access)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)

    {:noreply, socket}
  end
end
