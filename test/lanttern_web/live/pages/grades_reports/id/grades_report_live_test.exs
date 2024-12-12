defmodule LantternWeb.GradesReportLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.GradesReportsFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.GradingFixtures

  @live_view_base_path "/grades_reports"

  setup [:register_and_log_in_teacher]

  describe "Grades report live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      grades_report = grades_report_fixture(%{name: "Grades report ABC"})
      conn = get(conn, "#{@live_view_base_path}/#{grades_report.id}")

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Grades report ABC\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "show grades report", %{conn: conn} do
      cycle = SchoolsFixtures.cycle_fixture(%{name: "Some cycle 000"})
      scale = GradingFixtures.scale_fixture(%{name: "Some scale AZ", type: "ordinal"})

      _ordinal_value =
        GradingFixtures.ordinal_value_fixture(%{name: "Ordinal value A", scale_id: scale.id})

      grades_report =
        grades_report_fixture(%{
          name: "Some grade report ABC",
          info: "Some info XYZ",
          school_cycle_id: cycle.id,
          scale_id: scale.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{grades_report.id}")

      assert view |> has_element?("h1", "Some grade report ABC")
      assert view |> has_element?("p", "Some info XYZ")
      assert view |> has_element?("div", "Some cycle 000")
      assert view |> has_element?("div", "Some scale AZ")
      assert view |> has_element?("span", "Ordinal value A")
    end
  end
end
