defmodule LantternWeb.StudentHomeLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  @live_view_path "/student"

  setup [:register_and_log_in_student]

  describe "Student home live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Welcome!\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list student report cards", %{conn: conn, student: student} do
      report_card = report_card_fixture(%{name: "Some report card name ABC"})

      student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_student_access: true
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", "Some report card name ABC")

      view
      |> element("a", "Some report card name ABC")
      |> render_click()

      assert_redirect(view, "/student_report_card/#{student_report_card.id}")
    end
  end
end
