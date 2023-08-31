defmodule LantternWeb.CurriculumBNCCLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/curriculum/bncc_ef"

  describe "Curriculum BNCC live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>BNCC Ensino Fundamental<\/h1>/

      {:ok, _view, _html} = live(conn)
    end
  end
end
