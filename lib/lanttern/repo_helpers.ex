defmodule Lanttern.RepoHelpers do
  alias Lanttern.Repo
  import Ecto.Query, only: [from: 2]

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

  # skip if error
  defp handle_preload({:error, structs_or_struct_or_nil_or_tuple}, _preloads, _force) do
    {:error, structs_or_struct_or_nil_or_tuple}
  end

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

  @doc """
  Create naive timestamps.
  To be used in `inserted_at` and `updated_at`.
  """
  def naive_timestamp() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end

  @doc """
  Set the position in attrs for new entries, based on existing items in schema.
  """
  @spec set_position_in_attrs(Ecto.Queryable.t(), attrs :: map()) :: map()
  def set_position_in_attrs(queryable, attrs) do
    position =
      from(
        q in queryable,
        select: q.position,
        order_by: [desc: q.position],
        limit: 1
      )
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    cond do
      Enum.all?(attrs, fn {key, _value} -> is_atom(key) end) ->
        Map.put(attrs, :position, position)

      Enum.all?(attrs, fn {key, _value} -> is_binary(key) end) ->
        Map.put(attrs, "position", position)

      true ->
        raise("Mixed atom and string keys in attr")
    end
  end
end
