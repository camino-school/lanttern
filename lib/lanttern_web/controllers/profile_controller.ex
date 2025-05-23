defmodule LantternWeb.ProfileController do
  use LantternWeb, :controller

  import LantternWeb.IdentityHelpers
  import LantternWeb.SchoolsHelpers
  alias Lanttern.Identity
  alias Lanttern.Identity.Profile

  def index(conn, _params) do
    profiles =
      Identity.list_profiles(preloads: [:user, :student, :staff_member, :guardian_of_student])

    render(conn, :index, profiles: profiles)
  end

  def new(conn, _params) do
    user_options = generate_user_options()
    student_options = generate_student_options()
    staff_member_options = generate_staff_member_options()
    changeset = Identity.change_profile(%Profile{})

    render(conn, :new,
      user_options: user_options,
      student_options: student_options,
      staff_member_options: staff_member_options,
      changeset: changeset
    )
  end

  def create(conn, %{"profile" => profile_params}) do
    case Identity.create_profile(profile_params) do
      {:ok, profile} ->
        conn
        |> put_flash(:info, "Profile created successfully.")
        |> redirect(to: ~p"/admin/profiles/#{profile}")

      {:error, %Ecto.Changeset{} = changeset} ->
        user_options = generate_user_options()
        student_options = generate_student_options()
        staff_member_options = generate_staff_member_options()

        render(conn, :new,
          user_options: user_options,
          student_options: student_options,
          staff_member_options: staff_member_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    profile =
      Identity.get_profile!(id, preloads: [:user, :student, :staff_member, :guardian_of_student])

    render(conn, :show, profile: profile)
  end

  def edit(conn, %{"id" => id}) do
    profile = Identity.get_profile!(id)
    user_options = generate_user_options()
    student_options = generate_student_options()
    staff_member_options = generate_staff_member_options()
    changeset = Identity.change_profile(profile)

    render(conn, :edit,
      user_options: user_options,
      student_options: student_options,
      staff_member_options: staff_member_options,
      profile: profile,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "profile" => profile_params}) do
    profile = Identity.get_profile!(id)

    case Identity.update_profile(profile, profile_params) do
      {:ok, profile} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: ~p"/admin/profiles/#{profile}")

      {:error, %Ecto.Changeset{} = changeset} ->
        user_options = generate_user_options()
        student_options = generate_student_options()
        staff_member_options = generate_staff_member_options()

        render(conn, :edit,
          user_options: user_options,
          student_options: student_options,
          staff_member_options: staff_member_options,
          profile: profile,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    profile = Identity.get_profile!(id)
    {:ok, _profile} = Identity.delete_profile(profile)

    conn
    |> put_flash(:info, "Profile deleted successfully.")
    |> redirect(to: ~p"/admin/profiles")
  end
end
