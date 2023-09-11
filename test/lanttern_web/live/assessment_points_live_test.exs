defmodule LantternWeb.AssessmentPointsLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/assessment_points"

  describe "Assessment points live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Assessment points\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "navigation to assessment points explorer", %{conn: conn} do
      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", "Explore")
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/assessment_points/explorer"
    end
  end
end
