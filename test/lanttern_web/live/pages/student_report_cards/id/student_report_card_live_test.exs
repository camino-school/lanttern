defmodule LantternWeb.StudentReportCardLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.GradesReportsFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path_base "/student_report_cards"

  setup [:register_and_log_in_staff_member]

  describe "Student report card live view basic navigation" do
    test "disconnected and connected mount", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: staff_member.school_id})

      report_card = report_card_fixture(%{name: "Some report card name abc"})

      student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      conn = get(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      response = html_response(conn, 200)
      assert response =~ ~r"<h1 .+>\s*Student ABC\s*<\/h1>"
      assert response =~ ~r"<h2 .+>\s*Some report card name abc\s*<\/h2>"

      {:ok, _view, _html} = live(conn)
    end

    test "display student report card correctly", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: staff_member.school_id})

      grades_report =
        GradesReportsFixtures.grades_report_fixture(%{
          name: "Some grades report",
          info: "Some grading info"
        })

      report_card =
        report_card_fixture(%{
          school_cycle_id: cycle.id,
          name: "Some report card name abc",
          grades_report_id: grades_report.id
        })

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          comment: "student abc comment",
          footnote: "student abc footnote"
        })

      subject = TaxonomyFixtures.subject_fixture(%{name: "Some subject SSS"})
      year = TaxonomyFixtures.year_fixture(%{name: "Some year YYY"})

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "Strand for report ABC",
          type: "Some type XYZ",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      scale = GradingFixtures.scale_fixture()

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{strand_id: strand.id, scale_id: scale.id})

      _entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      assert view |> has_element?("h1", "Student ABC")
      assert view |> has_element?("h2", "Some report card name abc")
      assert view |> has_element?("p", "Some grading info")
      assert view |> has_element?("p", "student abc comment")
      assert view |> has_element?("p", "student abc footnote")

      # strand report card
      assert view
             |> has_element?("#strand-report-#{strand_report.id} h5", "Strand for report ABC")

      assert view |> has_element?("#strand-report-#{strand_report.id} p", "Some type XYZ")
      assert view |> has_element?("#strand-report-#{strand_report.id} span", "Some subject SSS")
      assert view |> has_element?("#strand-report-#{strand_report.id} span", "Some year YYY")

      # navigation to details
      view
      |> element("#strand-report-#{strand_report.id} a", "Strand for report ABC")
      |> render_click()

      assert_redirect(
        view,
        "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
      )
    end

    test "display student report card correctly for students", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id
        })

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(conn, "#{@live_view_path_base}/#{student_report_card.id}")
      end)

      # update allow_access and assert

      Lanttern.Reporting.update_student_report_card(student_report_card, %{
        allow_student_access: true
      })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      assert view |> has_element?("h1", student.name)
      assert view |> has_element?("h2", "Some report card name abc")
    end

    test "display student report card correctly for guardians", context do
      %{conn: conn, student: student} = register_and_log_in_guardian(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id
        })

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(conn, "#{@live_view_path_base}/#{student_report_card.id}")
      end)

      # update allow_access and assert

      Lanttern.Reporting.update_student_report_card(student_report_card, %{
        allow_guardian_access: true
      })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      assert view |> has_element?("h1", student.name)
      assert view |> has_element?("h2", "Some report card name abc")
    end
  end
end
