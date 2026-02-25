defmodule LantternWeb.StudentReportCardStrandReportLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path_base "/student_report_cards"

  describe "Student strand report live view basic navigation" do
    test "disconnected and connected mount", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: staff_member.school_id})

      report_card = report_card_fixture(%{name: "Some report card name abc"})

      student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      strand = LearningContextFixtures.strand_fixture(%{name: "Some strand name for report"})

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      conn =
        get(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      response = html_response(conn, 200)
      assert response =~ ~r"<h1 .+>\s*Some strand name for report\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display student strand report correctly", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      student =
        SchoolsFixtures.student_fixture(%{name: "Student ABC", school_id: staff_member.school_id})

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
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id,
          description: "Some description for strand report"
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      # strand report card
      assert view |> has_element?("h1", "Strand for report ABC")
      assert view |> has_element?("p", "Some type XYZ")
      assert view |> has_element?("span", "Some subject SSS")
      assert view |> has_element?("span", "Some year YYY")
    end

    test "display student strand report correctly for students", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      student_report_card =
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

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )
      end)

      # update allow_access and assert

      Lanttern.Reporting.update_student_report_card(student_report_card, %{
        allow_student_access: true
      })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      assert view |> has_element?("h1", "Strand for report ABC")
    end

    test "hide moments tab when there's none", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      report_card = report_card_fixture()

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      refute view |> has_element?("a", "Moments")

      # add moment and assert again

      LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      assert view |> has_element?("a", "Moments")
    end

    test "display student strand report correctly for guardians", context do
      %{conn: conn, student: student} = register_and_log_in_guardian(context)

      cycle = SchoolsFixtures.cycle_fixture(%{name: "Cycle 2024"})

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, name: "Some report card name abc"})

      student_report_card =
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

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )
      end)

      # update allow_access and assert

      Lanttern.Reporting.update_student_report_card(student_report_card, %{
        allow_guardian_access: true
      })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}"
        )

      assert view |> has_element?("h1", "Strand for report ABC")
    end

    test "renders moments tab", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      student =
        SchoolsFixtures.student_fixture(%{school_id: staff_member.school_id})

      report_card = report_card_fixture()

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id
        })

      strand = LearningContextFixtures.strand_fixture()

      strand_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id
        })

      LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment ABC"})

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{student_report_card.id}/strand_report/#{strand_report.id}/moments"
        )

      assert view |> has_element?("h5", "Moment ABC")
    end
  end
end
