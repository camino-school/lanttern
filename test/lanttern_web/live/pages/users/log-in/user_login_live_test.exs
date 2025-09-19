defmodule LantternWeb.UserLive.LoginTest do
  use LantternWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Lanttern"
      assert html =~ "sign in"
    end
  end
end
