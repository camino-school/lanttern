defmodule LantternWeb.IdentityHelpers do
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
    Identity.list_profiles(preloads: [:teacher, :student])
    |> Enum.map(fn p -> {profile_name(p), p.id} end)
  end

  defp profile_name(%{type: "teacher", teacher: teacher}),
    do: "Teacher: #{teacher.name}"

  defp profile_name(%{type: "student", student: student}),
    do: "Student: #{student.name}"

  @doc """
  Generate list of teacher profiles to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_teacher_profile_options()
      [{"name", 1}, ...]
  """
  def generate_teacher_profile_options() do
    Identity.list_profiles(type: "teacher", preloads: :teacher)
    |> Enum.map(fn p -> {p.teacher.name, p.id} end)
  end
end
