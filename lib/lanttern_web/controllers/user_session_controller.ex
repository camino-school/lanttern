defmodule LantternWeb.UserSessionController do
  use LantternWeb, :controller

  alias Lanttern.Identity
  alias LantternWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Identity.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def google_sign_in(conn, %{"credential" => credential}) do
    handle_google_sign_in_response(
      conn,
      Lanttern.GoogleToken.verify_and_validate(credential)
    )
  end

  defp handle_google_sign_in_response(conn, {:ok, claims}) do
    %{"email" => email, "name" => name} = claims

    if user = Identity.get_user_by_email(email) do
      conn
      |> put_flash(:info, "Welcome back #{name}!")
      |> UserAuth.log_in_user(user)
    else
      conn
      |> put_flash(:error, "User not registered in Lanttern")
      |> redirect(to: ~p"/users/log_in")
    end
  end

  defp handle_google_sign_in_response(conn, {:error, error_reason}) do
    conn
    |> put_flash(:error, error_reason[:message])
    |> redirect(to: ~p"/users/log_in")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
