defmodule LantternWeb.StrandReportLive.StrandReportAssessmentComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures
  import Lanttern.Factory
  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures

  @live_view_path_base "/strand_report"

  describe "StrandReportAssessmentComponent" do
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

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
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("h4", "Moment Alpha")
      assert view |> has_element?("[id*='assessment-point']", "Assessment Point Alpha")
    end

    test "does not show hidden assessment points", context do
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_visible =
        assessment_point_fixture(%{
          name: "AP Visible",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_hidden =
        assessment_point_fixture(%{
          name: "AP Hidden",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          is_hidden: true
        })

      _entry_visible =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_visible.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      _entry_hidden =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_hidden.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("[id*='assessment-point']", "AP Visible")
      refute view |> has_element?("[id*='assessment-point']", "AP Hidden")
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = insert(:curriculum_item)

      _ap_without_entry =
        assessment_point_fixture(%{
          name: "AP Without Entry",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      refute view |> has_element?("h4", "Moment Beta")
      refute view |> has_element?("[id*='assessment-point']", "AP Without Entry")
    end

    test "does not show hidden strand goal cards", context do
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci_visible = insert(:curriculum_item, name: "Curriculum Item Visible")
      ci_hidden = insert(:curriculum_item, name: "Curriculum Item Hidden")

      ap_visible =
        assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: ci_visible.id
        })

      ap_hidden =
        assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: ci_hidden.id,
          is_hidden: true
        })

      _entry_visible =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_visible.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      _entry_hidden =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_hidden.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("[id^='goal-']", "Curriculum Item Visible")
      refute view |> has_element?("[id^='goal-']", "Curriculum Item Hidden")
    end
  end

  describe "StrandGoalDetailsOverlayComponent" do
    test "does not show hidden moment assessment points in formative assessment section",
         context do
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      strand_goal_ap =
        assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      _strand_goal_entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: strand_goal_ap.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      moment_visible =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Visible"})

      moment_hidden =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Hidden"})

      ap_in_visible_moment =
        assessment_point_fixture(%{
          moment_id: moment_visible.id,
          curriculum_item_id: ci.id,
          scale_id: scale.id
        })

      ap_in_hidden_moment =
        assessment_point_fixture(%{
          moment_id: moment_hidden.id,
          curriculum_item_id: ci.id,
          scale_id: scale.id,
          is_hidden: true
        })

      _entry_visible =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_in_visible_moment.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      _entry_hidden =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_in_hidden_moment.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/assessment/strand_goal/#{strand_goal_ap.id}"
        )

      assert view |> has_element?("#moments-assessment-points-and-entries", "Moment Visible")
      refute view |> has_element?("#moments-assessment-points-and-entries", "Moment Hidden")
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item, %{name: "Some Curriculum Item"})

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
          "#{@live_view_path_base}/#{strand_report.id}/assessment/assessment_point/#{ap.id}"
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

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = insert(:curriculum_item)

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
          "#{@live_view_path_base}/#{strand_report.id}/assessment/assessment_point/#{unrelated_ap.id}"
        )

      refute view |> has_element?("h3", "Unrelated AP")
    end
  end
end
