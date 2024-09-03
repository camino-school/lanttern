defmodule LantternWeb.StudentStrandReportLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path_base "/strand_report"

  describe "Student strand report live view basic navigation" do
    test "disconnected and connected mount", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture(%{name: "Some report card name abc"})

      _student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      strand = LearningContextFixtures.strand_fixture(%{name: "Some strand name for report"})

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      conn =
        get(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}"
        )

      response = html_response(conn, 200)
      assert response =~ ~r"<h1 .+>\s*Some strand name for report\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display student strand report correctly for students", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id
        })

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "Strand for report ABC"
        })

      strand_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}"
        )

      assert view |> has_element?("h1", "Strand for report ABC")
    end

    test "display student strand report correctly for guardians", context do
      %{conn: conn, student: student} = register_and_log_in_guardian(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      _student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id
        })

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "Strand for report ABC"
        })

      strand_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}"
        )

      assert view |> has_element?("h1", "Strand for report ABC")
    end
  end
end
