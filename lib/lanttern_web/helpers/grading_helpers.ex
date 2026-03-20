defmodule LantternWeb.GradingHelpers do
  @moduledoc """
  Helper functions related to `Grading` context
  """

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Grading
  alias Lanttern.Identity.Scope

  @doc """
  Generate list of scales to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  Accepts `opts` arg, which will be forwarded to `Grading.list_scales/1` and supports
  an extra `current_scale_id` to force a scale option inclusion (use case: scale options
  with `only_active` filter, but current scale is inactive).

  ## Examples

      iex> generate_scale_options()
      ["scale name": 1, ...]
  """

  def generate_scale_options(%Scope{} = scope, opts \\ []) do
    Grading.list_scales(scope, opts)
    |> Enum.map(fn s -> {s.name, s.id} end)
    |> maybe_inject_deactivated_scale(Keyword.get(opts, :current_scale_id), scope)
  end

  defp maybe_inject_deactivated_scale(scale_options, nil, _scope), do: scale_options

  defp maybe_inject_deactivated_scale(scale_options, current_scale_id, scope) do
    options_ids = Enum.map(scale_options, fn {_scale, id} -> id end)

    if current_scale_id in options_ids do
      scale_options
    else
      current_scale = Grading.get_scale!(scope, current_scale_id)

      [
        {"#{current_scale.name} (#{gettext("current, deactivated")})", current_scale_id}
        | scale_options
      ]
    end
  end
end
