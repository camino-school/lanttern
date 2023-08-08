defmodule LantternWeb.AssessmentPointsExplorerLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @live_view_path "/assessment_points/explorer"

  describe "Assessment points explorer live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>Assessment points explorer<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display list of links for assessment points", %{conn: conn} do
      %{name: name_1} = assessment_point_fixture()
      %{name: name_2} = assessment_point_fixture()
      %{name: name_3} = assessment_point_fixture()

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("li > a", name_1)
      assert view |> has_element?("li > a", name_2)
      assert view |> has_element?("li > a", name_3)
    end

    test "navigation to assessment point details", %{conn: conn} do
      %{id: id, name: name} = assessment_point_fixture()

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("li > a", name)
      |> render_click()

      path = assert_patch(view)
      assert path == "/assessment_points/#{id}"
    end
  end
end
