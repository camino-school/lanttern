defmodule LantternWeb.DashboardLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/dashboard"

  setup :register_and_log_in_teacher

  describe "Dashboard live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Dashboard 🚧\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end
  end
end
