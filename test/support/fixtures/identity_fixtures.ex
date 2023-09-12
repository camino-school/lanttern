defmodule Lanttern.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Identity` context.
  """

  import Ecto.Query, only: [from: 2]
  import Lanttern.SchoolsFixtures

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Lanttern.Identity.register_user()

    user
  end

  def root_admin_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    # update is_root_admin in DB using query
    # (we won't add changesets and public API to create a root admin)
    from(u in Lanttern.Identity.User, where: u.id == ^user.id)
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
      |> Lanttern.Identity.create_profile()

    profile
  end

  @doc """
  Generate a teacher profile.
  """
  def teacher_profile_fixture(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || user_fixture().id
    teacher_id = Map.get(attrs, :teacher_id) || teacher_fixture().id

    {:ok, profile} =
      attrs
      |> Enum.into(%{
        type: "teacher",
        user_id: user_id,
        teacher_id: teacher_id
      })
      |> Lanttern.Identity.create_profile()

    profile
  end
end
