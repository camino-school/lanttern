defmodule LantternWeb.AssessmentPointsExplorerLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @live_view_path "/assessment_points/explorer"

  setup :register_and_log_in_user

  describe "Assessment points explorer live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Assessment points explorer\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display list of links for assessment points", %{conn: conn} do
      std_1 = Lanttern.SchoolsFixtures.student_fixture()
      std_2 = Lanttern.SchoolsFixtures.student_fixture()
      std_3 = Lanttern.SchoolsFixtures.student_fixture()

      ast_1 = assessment_point_fixture()
      ast_2 = assessment_point_fixture()
      ast_3 = assessment_point_fixture()

      assessment_point_entry_fixture(%{student_id: std_1.id, assessment_point_id: ast_1.id})
      assessment_point_entry_fixture(%{student_id: std_2.id, assessment_point_id: ast_2.id})
      assessment_point_entry_fixture(%{student_id: std_3.id, assessment_point_id: ast_3.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", ast_1.name)
      assert view |> has_element?("a", ast_2.name)
      assert view |> has_element?("a", ast_3.name)
    end

    test "navigation to assessment point details", %{conn: conn} do
      %{id: id, name: name} = assessment_point_fixture(%{name: "not any name"})
      assessment_point_entry_fixture(%{assessment_point_id: id})

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", name)
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/assessment_points/#{id}"
    end
  end
end
