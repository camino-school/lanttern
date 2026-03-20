defmodule LantternWeb.StrandReportLessonLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures
  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.CurriculaFixtures

  @live_view_path_base "/strand_report"

  describe "lesson assessment point cards" do
    test "renders assessment point cards for student entries", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = insert(:report_card)

      _student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: report_card,
          allow_student_access: true
        )

      strand = insert(:strand)
      strand_report = insert(:strand_report, report_card: report_card, strand: strand)
      lesson = insert(:lesson, strand: strand, name: "Lesson Alpha", is_published: true)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = CurriculaFixtures.curriculum_item_fixture()

      ap =
        assessment_point_fixture(%{
          name: "AP in Lesson",
          lesson_id: lesson.id,
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

      conn
      |> visit("#{@live_view_path_base}/#{strand_report.id}/lesson/#{lesson.id}")
      |> assert_has("[id*='assessment-point']", text: "AP in Lesson")
    end

    test "does not show assessment points with no entry for the student", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = insert(:report_card)

      _student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: report_card,
          allow_student_access: true
        )

      strand = insert(:strand)
      strand_report = insert(:strand_report, report_card: report_card, strand: strand)
      lesson = insert(:lesson, strand: strand, is_published: true)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = CurriculaFixtures.curriculum_item_fixture()

      _ap_without_entry =
        assessment_point_fixture(%{
          name: "AP Without Entry",
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      conn
      |> visit("#{@live_view_path_base}/#{strand_report.id}/lesson/#{lesson.id}")
      |> refute_has("[id*='assessment-point']", text: "AP Without Entry")
    end
  end

  describe "StudentAssessmentPointDetailsOverlayComponent in lesson view" do
    test "renders assessment point details overlay when navigating to ap id path", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = insert(:report_card)

      _student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: report_card,
          allow_student_access: true
        )

      strand = insert(:strand)
      strand_report = insert(:strand_report, report_card: report_card, strand: strand)
      lesson = insert(:lesson, strand: strand, is_published: true)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = CurriculaFixtures.curriculum_item_fixture(%{name: "Some Curriculum Item"})

      ap =
        assessment_point_fixture(%{
          name: "AP With Details",
          lesson_id: lesson.id,
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

      conn
      |> visit(
        "#{@live_view_path_base}/#{strand_report.id}/lesson/#{lesson.id}/assessment_point/#{ap.id}"
      )
      |> assert_has("h3", text: "AP With Details")
      |> assert_has("p", text: "Some Curriculum Item")
    end

    test "does not render overlay for assessment points unrelated to the student", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = insert(:report_card)

      _student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: report_card,
          allow_student_access: true
        )

      strand = insert(:strand)
      strand_report = insert(:strand_report, report_card: report_card, strand: strand)
      lesson = insert(:lesson, strand: strand, is_published: true)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = CurriculaFixtures.curriculum_item_fixture()

      unrelated_ap =
        assessment_point_fixture(%{
          name: "Unrelated AP",
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      conn
      |> visit(
        "#{@live_view_path_base}/#{strand_report.id}/lesson/#{lesson.id}/assessment_point/#{unrelated_ap.id}"
      )
      |> refute_has("h3", text: "Unrelated AP")
    end
  end
end
