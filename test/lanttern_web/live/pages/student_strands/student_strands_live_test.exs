defmodule LantternWeb.StudentStrandsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.ReportingFixtures

  @live_view_path "/student_strands"

  setup [:register_and_log_in_student]

  describe "Student strands live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Strands\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list strands linked to report cards", %{conn: conn, student: student} do
      report_card = ReportingFixtures.report_card_fixture()

      _student_report_card =
        ReportingFixtures.student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      strand_a = LearningContextFixtures.strand_fixture(%{name: "AAA"})
      strand_b = LearningContextFixtures.strand_fixture(%{name: "BBB"})

      _strand_a_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_a.id
        })

      _strand_b_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_b.id
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "AAA")
      assert view |> has_element?("h5", "BBB")
    end
  end
end
