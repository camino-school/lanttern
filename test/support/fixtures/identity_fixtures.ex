defmodule Lanttern.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Identity` context.
  """

  import Ecto.Query, only: [from: 2]
  import Lanttern.SchoolsFixtures
  alias Lanttern.Identity
  alias Lanttern.Personalization

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Identity.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    # Directly confirm the user without going through magic link flow
    {:ok, user} =
      user
      |> Lanttern.Identity.User.confirm_changeset()
      |> Lanttern.Repo.update()

    user
  end

  def root_admin_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    # update is_root_admin in DB using query
    # (we won't add changesets and public API to create a root admin)
    from(u in Identity.User, where: u.id == ^user.id)
    |> Lanttern.Repo.update_all(set: [is_root_admin: true])

    user |> Map.put(:is_root_admin, true)
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a student profile.
  """
  def student_profile_fixture(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || user_fixture().id
    student_id = Map.get(attrs, :student_id) || student_fixture().id

    {:ok, profile} =
      attrs
      |> Enum.into(%{
        type: "student",
        user_id: user_id,
        student_id: student_id
      })
      |> Identity.create_profile()

    profile
  end

  @doc """
  Generate a staff member profile.
  """
  def staff_member_profile_fixture(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || user_fixture().id
    staff_member_id = Map.get(attrs, :staff_member_id) || staff_member_fixture().id

    {:ok, profile} =
      attrs
      |> Enum.into(%{
        type: "staff",
        user_id: user_id,
        staff_member_id: staff_member_id
      })
      |> Identity.create_profile()

    profile
  end

  @doc """
  Generate a guardian profile.
  """
  def guardian_profile_fixture(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || user_fixture().id
    guardian_of_student_id = Map.get(attrs, :guardian_of_student_id) || student_fixture().id

    {:ok, profile} =
      attrs
      |> Enum.into(%{
        type: "guardian",
        user_id: user_id,
        guardian_of_student_id: guardian_of_student_id
      })
      |> Identity.create_profile()

    profile
  end

  @doc """
  Generate a staff member user that emulates the `current_user` in socket.

  Creates the user, profile, and staff member needed to structure the current user.
  """
  def current_staff_member_user_fixture(attrs \\ %{}, permissions \\ []) do
    user = user_fixture()
    staff_member = staff_member_fixture(attrs) |> Lanttern.Repo.preload(:school)

    staff_member_profile =
      staff_member_profile_fixture(%{user_id: user.id, staff_member_id: staff_member.id})

    Personalization.set_profile_settings(staff_member_profile.id, %{permissions: permissions})

    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user
    |> Map.put(
      :current_profile,
      %Identity.Profile{
        id: staff_member_profile.id,
        name: staff_member.name,
        type: "staff",
        staff_member_id: staff_member.id,
        school_id: staff_member.school.id,
        school_name: staff_member.school.name,
        permissions: permissions
      }
    )
  end

  @doc """
  Generate a scope for testing based on a user fixture.

  Defaults to creating a scope for a staff member user with no permissions.

  ## Examples

      iex> scope_fixture()
      %Scope{user: %User{}, profile: %Profile{}, school_id: 1}

      iex> scope_fixture(permissions: ["manage_posts"])
      %Scope{user: %User{}, profile: %Profile{}, permissions: ["manage_posts"]}

  """
  def scope_fixture(attrs \\ %{}) do
    permissions = Map.get(attrs, :permissions, [])
    user = current_staff_member_user_fixture(%{}, permissions)
    Identity.Scope.for_user(user)
  end

  @doc """
  Generate a staff member scope for testing.

  Creates a scope with a staff member profile.

  ## Options

  - `:permissions` - list of permissions to assign to the scope
  - Other attrs are passed to staff_member_fixture

  """
  def staff_scope_fixture(attrs \\ %{}) do
    scope_fixture(attrs)
  end

  @doc """
  Generate a student scope for testing.

  Creates a scope with a student profile.
  """
  def student_scope_fixture(attrs \\ %{}) do
    user = user_fixture()
    student = student_fixture(attrs) |> Lanttern.Repo.preload(:school)

    student_profile =
      student_profile_fixture(%{user_id: user.id, student_id: student.id})

    user =
      user
      |> Map.put(
        :current_profile,
        %Identity.Profile{
          id: student_profile.id,
          name: student.name,
          type: "student",
          student_id: student.id,
          school_id: student.school.id,
          school_name: student.school.name,
          permissions: []
        }
      )

    Identity.Scope.for_user(user)
  end

  @doc """
  Generate a guardian scope for testing.

  Creates a scope with a guardian profile.
  """
  def guardian_scope_fixture(attrs \\ %{}) do
    user = user_fixture()
    student = student_fixture(attrs) |> Lanttern.Repo.preload(:school)

    guardian_profile =
      guardian_profile_fixture(%{user_id: user.id, guardian_of_student_id: student.id})

    user =
      user
      |> Map.put(
        :current_profile,
        %Identity.Profile{
          id: guardian_profile.id,
          name: "Guardian of #{student.name}",
          type: "guardian",
          school_id: student.school.id,
          school_name: student.school.name,
          permissions: []
        }
      )

    Identity.Scope.for_user(user)
  end

  # helpers

  def maybe_gen_profile_id(attrs, opts \\ [])

  def maybe_gen_profile_id(%{profile_id: profile_id} = _attrs, _opts),
    do: profile_id

  def maybe_gen_profile_id(attrs, foreign_key: foreign_key) do
    case Map.get(attrs, foreign_key) do
      nil -> staff_member_profile_fixture().id
      id -> id
    end
  end

  def maybe_gen_profile_id(_attrs, _opts),
    do: staff_member_profile_fixture().id
end
