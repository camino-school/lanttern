defmodule LantternWeb.UserController do
  use LantternWeb, :controller

  alias Lanttern.Identity
  alias Lanttern.Identity.User

  def index(conn, _params) do
    users = Identity.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _params) do
    changeset = Identity.change_user_email(%User{})

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # the form doesn't have the password field because we're only using
    # Google Sign In, but we need a password in order to create the user
    user_params = Map.put(user_params, "password", Ecto.UUID.generate())

    case Identity.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: ~p"/admin/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Identity.get_user!(id)
    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Identity.get_user!(id)
    changeset = Identity.change_user_email(user)

    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Identity.get_user!(id)

    case Identity.admin_update_user_email(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: ~p"/admin/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Identity.get_user!(id)
    {:ok, _user} = Identity.admin_delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: ~p"/admin/users")
  end
end
