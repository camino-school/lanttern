defmodule Lanttern.RepoHelpers do
  alias Lanttern.Repo

  @doc """
  Preload associated data based on provided values.

  It's a thin wrapper around `Repo.preload/3` that allows it to be used
  in all functions that support options as keyword lists (specifically the `:preloads` opt)
  """
  def maybe_preload(structs_or_struct_or_nil, [preloads: preloads] = _opts) do
    structs_or_struct_or_nil
    |> Repo.preload(preloads)
  end

  def maybe_preload(structs_or_struct_or_nil, _opts), do: structs_or_struct_or_nil
end
