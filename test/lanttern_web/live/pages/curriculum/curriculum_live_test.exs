defmodule LantternWeb.CurriculumLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/curriculum"

  setup :register_and_log_in_user

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Curriculum\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "navigation to BNCC EF", %{conn: conn} do
      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", "BNCC EF")
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/curriculum/bncc_ef"
    end
  end
end
