defmodule LantternWeb.StudentReportCardLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path_base "/student_report_card"

  setup [:register_and_log_in_teacher]

  describe "Student report card live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, teacher: teacher} do
      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: teacher.school_id})

      report_card = report_card_fixture(%{name: "Some report card name abc"})

      student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      conn = get(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      response = html_response(conn, 200)
      assert response =~ ~r"<h1 .+>\s*Student ABC\s*<\/h1>"
      assert response =~ ~r"<h2 .+>\s*Some report card name abc\s*<\/h2>"

      {:ok, _view, _html} = live(conn)
    end

    test "display student report card correctly", %{conn: conn, teacher: teacher} do
      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: teacher.school_id})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

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

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{student_report_card.id}")

      assert view |> has_element?("h1", "Student ABC")
      assert view |> has_element?("h2", "Some report card name abc")
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
  end
end
