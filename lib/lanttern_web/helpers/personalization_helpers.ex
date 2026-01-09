defmodule LantternWeb.PersonalizationHelpers do
  @moduledoc """
  Helper functions related to `Personalization` context
  """

  alias Lanttern.Identity.Profile
  alias Lanttern.Personalization

  @permission_to_option_map %{
    "students_records_full_access" => "Students records full access",
    "school_management" => "School management",
    "content_management" => "Content management",
    "communication_management" => "Communication management",
    "ilp_management" => "ILP management",
    "agents_management" => "AI agents management"
  }

  @doc """
  Generate list of permissions to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_permission_options()
      [{"permission", "value"}, ...]
  """
  def generate_permission_options do
    Personalization.list_valid_permissions()
    |> Enum.map(fn p -> {@permission_to_option_map[p], p} end)
  end

  @doc """
  Basic util function to check for profile permission in on view mount
  """
  def profile_has_permission?(%Profile{permissions: permissions}, required_permission),
    do: required_permission in permissions
end
