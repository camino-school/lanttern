defmodule LantternWeb.UserLive.LoginTest do
  use LantternWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lanttern.IdentityFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Lanttern"
      assert html =~ "sign in"
    end
  end

  describe "user login - magic link" do
    test "sends magic link email when user exists", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in/code?email=#{URI.encode(user.email)}")

      # We've sent a sign-in link to...
      assert html =~ "sent a sign-in link to"

      assert Lanttern.Repo.get_by!(Lanttern.Identity.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(
          conn,
          ~p"/users/log-in/code?email=#{URI.encode("idonotexist@example.com")}"
        )

      # We've sent a sign-in link to...
      assert html =~ "sent a sign-in link to"
    end
  end
end
