defmodule LantternWeb.StrandReportLive.StrandReportOngoingAssessmentComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures
  import Lanttern.ReportingFixtures

  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.LearningContextFixtures

  @live_view_path_base "/strand_report"

  describe "StrandReportOngoingAssessmentComponent" do
    test "renders moment names and assessment point cards for student entries", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture()

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Alpha"})

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ci = CurriculaFixtures.curriculum_item_fixture()

      ap =
        assessment_point_fixture(%{
          name: "Assessment Point Alpha",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      _entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/ongoing_assessment")

      assert view |> has_element?("h4", "Moment Alpha")
      assert view |> has_element?("[id*='assessment-point']", "Assessment Point Alpha")
    end

    test "does not show assessment points that have no entry for the student", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture()

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Beta"})

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ci = CurriculaFixtures.curriculum_item_fixture()

      _ap_without_entry =
        assessment_point_fixture(%{
          name: "AP Without Entry",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/ongoing_assessment")

      assert view |> has_element?("h4", "Moment Beta")
      refute view |> has_element?("[id*='assessment-point']", "AP Without Entry")
    end
  end

  describe "StudentAssessmentPointDetailsOverlayComponent" do
    test "renders assessment point details overlay when navigating to ap id path", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture()

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      ci = CurriculaFixtures.curriculum_item_fixture(%{name: "Some Curriculum Item"})

      ap =
        assessment_point_fixture(%{
          name: "AP With Details",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      # entry must have marking (ordinal_value_id set) for assign_entry to load it
      _entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/ongoing_assessment/#{ap.id}"
        )

      assert view |> has_element?("h3", "AP With Details")
      assert view |> has_element?("p", "Some Curriculum Item")
    end

    test "does not render overlay for assessment points unrelated to the student", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture()

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ci = CurriculaFixtures.curriculum_item_fixture()

      # AP with no entry for the logged-in student
      unrelated_ap =
        assessment_point_fixture(%{
          name: "Unrelated AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/ongoing_assessment/#{unrelated_ap.id}"
        )

      refute view |> has_element?("h3", "Unrelated AP")
    end
  end
end
