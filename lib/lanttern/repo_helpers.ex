defmodule Lanttern.RepoHelpers do
  alias Lanttern.Repo

  @doc """
  Preload associated data based on provided values.

  It's a thin wrapper around `Repo.preload/3` that allows it to be used
  in all functions that support options as keyword lists (specifically the `:preloads` opt)
  """
  def maybe_preload({:ok, structs_or_struct_or_nil_or_tuple}, [preloads: preloads] = _opts) do
    preloaded =
      structs_or_struct_or_nil_or_tuple
      |> Repo.preload(preloads)

    {:ok, preloaded}
  end

  def maybe_preload({:error, error}, _opts), do: {:error, error}

  def maybe_preload(structs_or_struct_or_nil_or_tuple, [preloads: preloads] = _opts) do
    structs_or_struct_or_nil_or_tuple
    |> Repo.preload(preloads)
  end

  def maybe_preload(structs_or_struct_or_nil_or_tuple, _opts),
    do: structs_or_struct_or_nil_or_tuple
end
