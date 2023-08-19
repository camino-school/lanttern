defmodule Lanttern.RepoHelpers do
  alias Lanttern.Repo

  @doc """
  Preload associated data based on provided values.

  It's a thin wrapper around `Repo.preload/3` that allows it to be used
  in all functions that support options as keyword lists (specifically the `:preloads` opt)
  """
  def maybe_preload(structs_or_struct_or_nil_or_tuple, opts) do
    handle_preload(
      structs_or_struct_or_nil_or_tuple,
      Keyword.get(opts, :preloads),
      Keyword.get(opts, :force_preloads, false)
    )
  end

  defp handle_preload(structs_or_struct_or_nil_or_tuple, nil, _force),
    do: structs_or_struct_or_nil_or_tuple

  defp handle_preload({:ok, structs_or_struct_or_nil_or_tuple}, preloads, force) do
    preloaded =
      structs_or_struct_or_nil_or_tuple
      |> Repo.preload(preloads, force: force)

    {:ok, preloaded}
  end

  defp handle_preload(structs_or_struct_or_nil_or_tuple, preloads, force) do
    structs_or_struct_or_nil_or_tuple
    |> Repo.preload(preloads, force: force)
  end
end
