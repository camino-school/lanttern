defmodule LantternWeb.ChangesetHelpers do
  @moduledoc """
  Helper functions for working with Ecto changesets in views and live views.
  """

  import LantternWeb.CoreComponents, only: [translate_error: 1]

  @doc """
  Converts all errors in a changeset to a single joined string.

  Uses `translate_error/1` so gettext interpolation (e.g. `%{count}`) is handled.
  """
  def changeset_error_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    |> Enum.flat_map(fn {_field, msgs} -> msgs end)
    |> Enum.join(" ")
  end
end
