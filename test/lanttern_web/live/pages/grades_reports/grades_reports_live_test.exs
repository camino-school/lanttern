defmodule LantternWeb.GradesReportsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.GradesReportsFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.GradingFixtures

  @live_view_path "/grades_reports"

  setup [:register_and_log_in_teacher]

  describe "Grades reports live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Grades reports\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list grades reports", %{conn: conn} do
      cycle = SchoolsFixtures.cycle_fixture(%{name: "Some cycle 000"})
      scale = GradingFixtures.scale_fixture(%{name: "Some scale AZ", type: "ordinal"})

      _ordinal_value =
        GradingFixtures.ordinal_value_fixture(%{name: "Ordinal value A", scale_id: scale.id})

      _grades_report =
        grades_report_fixture(%{
          name: "Some grades report ABC",
          info: "Some info XYZ",
          school_cycle_id: cycle.id,
          scale_id: scale.id
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", "Some grades report ABC")
      assert view |> has_element?("p", "Some info XYZ")
      assert view |> has_element?("div", "Some cycle 000")
      assert view |> has_element?("div", "Some scale AZ")
      assert view |> has_element?("span", "Ordinal value A")
    end
  end
end
