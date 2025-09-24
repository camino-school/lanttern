defmodule LantternWeb.UserCodeLoginLiveTest do
  use LantternWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lanttern.IdentityFixtures

  alias Lanttern.Identity
  alias Lanttern.Identity.LoginCode
  alias Lanttern.Repo

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

    test "shows success message for non-existent user (security)", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/code?email=#{URI.encode(email)}")

      # For security: non-existent users get same behavior as existing users
      html =
        lv
        |> element("button", "Resend code")
        |> render_click()

      # Should show success message (same as existing users)
      assert html =~ "New code sent to your email."

      # Should have timer active (preventing enumeration attack)
      # Check that the button is disabled and shows countdown
      assert has_element?(lv, "button[disabled]", "Resend code in")
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

    test "invalidates code after 3 incorrect attempts", %{conn: conn} do
      email = unique_user_email()
      user = user_fixture(%{email: email})

      # Generate a login code for the user
      {:ok, _login_code} = Identity.generate_login_code(user)

      # Make 3 incorrect attempts
      for attempt <- 1..3 do
        conn =
          post(conn, ~p"/users/log-in", %{
            access_code: %{email: email, code: "wrong#{attempt}", remember_me: false}
          })

        if attempt < 3 do
          # First 2 attempts: should show invalid code error
          assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email)}"

          assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
                   "The code is invalid or has expired."
        else
          # 3rd attempt: code should be invalidated
          assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email)}"

          assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
                   "The code has been invalidated due to too many attempts."
        end
      end

      # Verify the code still exists in database (not deleted)
      login_code = get_login_code_by_email_for_testing(email)
      assert login_code != nil
      assert login_code.attempts >= 3
    end

    test "tracks attempts independently per email", %{conn: conn} do
      email1 = unique_user_email()
      email2 = unique_user_email()
      user1 = user_fixture(%{email: email1})
      user2 = user_fixture(%{email: email2})

      # Generate login codes for both users
      {:ok, _login_code1} = Identity.generate_login_code(user1)
      {:ok, _login_code2} = Identity.generate_login_code(user2)

      # Make 2 incorrect attempts for first email
      for attempt <- 1..2 do
        conn =
          post(conn, ~p"/users/log-in", %{
            access_code: %{email: email1, code: "wrong#{attempt}", remember_me: false}
          })

        assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email1)}"

        assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
                 "The code is invalid or has expired."
      end

      # Make 1 incorrect attempt for second email
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email2, code: "wrong1", remember_me: false}
        })

      assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email2)}"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "The code is invalid or has expired."

      # Verify both codes still exist (neither has reached 3 attempts)
      assert get_login_code_by_email_for_testing(email1) != nil
      assert get_login_code_by_email_for_testing(email2) != nil
    end

    test "rate limiting persists after code invalidation", %{conn: conn} do
      email = unique_user_email()
      user = user_fixture(%{email: email})

      # Generate a login code for the user
      {:ok, _login_code} = Identity.generate_login_code(user)

      # Make 3 incorrect attempts to invalidate the code
      for attempt <- 1..3 do
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: "wrong#{attempt}", remember_me: false}
        })
      end

      # Verify the code is invalidated
      login_code = get_login_code_by_email_for_testing(email)
      assert login_code.attempts >= 3

      # Check that rate limiting is still active
      assert {:error, :rate_limited} = Identity.request_login_code(email)

      # Verify remaining rate limit time exists
      {:ok, remaining_time} = Identity.get_rate_limit_remaining(email)
      assert remaining_time != nil
      assert remaining_time > 0
    end

    test "codes with 3+ attempts are permanently rejected even with correct code", %{conn: conn} do
      email = unique_user_email()
      _user = user_fixture(%{email: email})

      # Generate a login code and get the plain code
      {plain_code, hashed_code} = Lanttern.Identity.LoginCode.generate_code()
      login_code = Lanttern.Identity.LoginCode.build(email, hashed_code)
      {:ok, _} = Lanttern.Repo.insert(login_code)

      # Make 3 incorrect attempts first
      for attempt <- 1..3 do
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: "wrong#{attempt}", remember_me: false}
        })
      end

      # Verify the code has 3+ attempts
      updated_login_code = get_login_code_by_email_for_testing(email)
      assert updated_login_code.attempts >= 3

      # Now try with the CORRECT code - should still be rejected
      conn =
        post(conn, ~p"/users/log-in", %{
          access_code: %{email: email, code: plain_code, remember_me: false}
        })

      # Should be rejected even with correct code
      assert redirected_to(conn) == ~p"/users/log-in/code?email=#{URI.encode(email)}"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "The code has been invalidated due to too many attempts."
    end
  end

  # Test helper functions
  defp get_login_code_by_email_for_testing(email) do
    import Ecto.Query

    from(lc in LoginCode,
      where: lc.email == ^email,
      order_by: [desc: lc.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end
end
