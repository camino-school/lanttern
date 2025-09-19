defmodule LantternWeb.UserCodeLoginLiveTest do
  use LantternWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lanttern.IdentityFixtures

  alias Lanttern.Identity

  describe "code login page" do
    test "renders code login page with valid email", %{conn: conn} do
      email = unique_user_email()
      user_fixture(%{email: email})

      {:ok, _lv, html} = live(conn, ~p"/users/log-in/code?email=#{URI.encode(email)}")

      assert html =~ "Lanttern"
      assert html =~ "sign in"
      assert html =~ "Enter the 6-digit code sent to #{email}"
    end

    test "redirects to login page with invalid email", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/users/log-in/code?email=")
    end

    test "redirects to login page without email parameter", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/users/log-in/code")
    end

    test "displays error flash when accessing without email", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in/code")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid access to this page"
    end
  end

  describe "resend code" do
    test "successfully resends code for existing user", %{conn: conn} do
      email = unique_user_email()
      user_fixture(%{email: email})

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/code?email=#{URI.encode(email)}")

      html =
        lv
        |> element("button", "Resend code")
        |> render_click()

      # Check that the flash message appears in the rendered HTML
      assert html =~ "New code sent to your email."
    end

    test "shows error for non-existent user", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/code?email=#{URI.encode(email)}")

      # This should redirect when user is not found
      lv
      |> element("button", "Resend code")
      |> render_click()

      # Check that we get redirected when user doesn't exist
      # The actual implementation redirects to login page
      assert_redirect(lv, ~p"/users/log-in")
    end

    # Note: Testing delivery failure would require mocking the email service
    # This test is commented out as it requires additional test setup
  end

  describe "access code generation and verification" do
    test "successfully logs user in with correct code", %{conn: conn} do
      email = unique_user_email()
      _user = user_fixture(%{email: email})

      # Generate a login code and extract the plain code
      # We need to manually create the code to get the plain text version for testing
      {plain_code, hashed_code} = Lanttern.Identity.LoginCode.generate_code()

      # Insert the login code directly
      login_code = Lanttern.Identity.LoginCode.build(email, hashed_code)
      {:ok, _} = Lanttern.Repo.insert(login_code)

      # Submit the form with correct code directly to the controller
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: plain_code, remember_me: false}
        })

      # Check that user is logged in by verifying we're redirected to dashboard
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "shows invalid code error message with incorrect code", %{conn: conn} do
      email = unique_user_email()
      user = user_fixture(%{email: email})

      # Generate a login code for the user
      {:ok, _login_code} = Identity.generate_login_code(user)

      # Submit the form with incorrect code directly to the controller
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: "wrong6", remember_me: false}
        })

      # Check that we're redirected back to the code login page with error
      assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email)}"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "The code is invalid or has expired."
    end

    test "shows invalid code error for non-existent user email", %{conn: conn} do
      email = unique_user_email()
      # Don't create the user, so no login code exists

      # Submit the form with any code directly to the controller
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: "123456", remember_me: false}
        })

      # Check that we're redirected back to code page with invalid code error
      # (since no login code exists for this email)
      assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email)}"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "The code is invalid or has expired."
    end

    test "shows user not found error when login code exists but user is deleted", %{conn: conn} do
      email = unique_user_email()
      user = user_fixture(%{email: email})

      # Generate a login code and extract the plain code
      {plain_code, hashed_code} = Lanttern.Identity.LoginCode.generate_code()

      # Insert the login code directly
      login_code = Lanttern.Identity.LoginCode.build(email, hashed_code)
      {:ok, _} = Lanttern.Repo.insert(login_code)

      # Delete the user but keep the login code
      Lanttern.Repo.delete!(user)

      # Submit the form with the correct code
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: plain_code, remember_me: false}
        })

      # Check that we're redirected to login page with user not found error
      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "User not found."
    end
  end
end
