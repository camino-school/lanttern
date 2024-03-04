defmodule LantternWeb.CurriculaLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @live_view_path "/curriculum"

  setup :register_and_log_in_user

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Curriculum\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "listing curricula", %{conn: conn} do
      curriculum = curriculum_fixture(%{name: "Some curriculum AAA"})
      curriculum_fixture(%{name: "Some curriculum BBB"})

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> has_element?("a", "Some curriculum BBB")

      view
      |> element("a", "Some curriculum AAA")
      |> render_click()

      assert_redirect(view, ~p"/curriculum/#{curriculum}")
    end
  end
end
