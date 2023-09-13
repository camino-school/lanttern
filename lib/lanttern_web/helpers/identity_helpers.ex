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
end
