defmodule LantternWeb.IdentityHelpers do
  @moduledoc """
  Helper functions related to `Identity` context
  """

  alias Lanttern.Identity

  @doc """
  Generate list of users to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_user_options()
      [{"user email", 1}, ...]
  """
  def generate_user_options() do
    Identity.list_users()
    |> Enum.map(fn u -> {u.email, u.id} end)
  end

  @doc """
  Generate list of profiles to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_profile_options()
      [{"Teacher: name", 1}, ...]
  """
  def generate_profile_options() do
    Identity.list_profiles(preloads: [:staff_member, :student])
    |> Enum.map(fn p -> {profile_name(p), p.id} end)
  end

  defp profile_name(%{type: "staff", staff_member: staff_member}),
    do: "Staff member: #{staff_member.name}"

  defp profile_name(%{type: "student", student: student}),
    do: "Student: #{student.name}"

  @doc """
  Generate list of staff member profiles to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_staff_member_profile_options()
      [{"name", 1}, ...]
  """
  def generate_staff_member_profile_options() do
    Identity.list_profiles(type: "staff", preloads: :staff_member)
    |> Enum.map(fn p -> {p.staff_member.name, p.id} end)
  end
end
