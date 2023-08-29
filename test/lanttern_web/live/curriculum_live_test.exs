defmodule LantternWeb.CurriculumLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/curriculum"

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>Curriculum<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "navigation to bncc", %{conn: conn} do
      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", "BNCC")
      |> render_click()

      path = assert_patch(view)
      assert path == "/curriculum/bncc"
    end
  end
end
