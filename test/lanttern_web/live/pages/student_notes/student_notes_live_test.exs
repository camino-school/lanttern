defmodule LantternWeb.StudentNotesLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.NotesFixtures
  alias Lanttern.ReportingFixtures

  @live_view_path "/student_notes"

  setup [:register_and_log_in_student]

  describe "Student home live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*My strands notes\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list strands linked to report cards", %{conn: conn, student: student, user: user} do
      report_card = ReportingFixtures.report_card_fixture()

      _student_report_card =
        ReportingFixtures.student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand_with_note = LearningContextFixtures.strand_fixture(%{name: "AAA"})
      strand_without_note = LearningContextFixtures.strand_fixture(%{name: "BBB"})
      _strand_note = NotesFixtures.strand_note_fixture(user, strand_with_note.id)

      _strand_with_note_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_with_note.id
        })

      _strand_without_note_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_without_note.id
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "AAA")
      assert view |> has_element?("button", "View/edit note")

      assert view |> has_element?("h5", "BBB")
      assert view |> has_element?("button", "Add note")
    end
  end
end
