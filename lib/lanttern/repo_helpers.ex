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
  Thin wrapper around `Flop.validate_and_run!/3` to handle tupple return
  """
  def handle_flop_validate_and_run(queryable, map_or_flop \\ %{}, opts \\ []) do
    {result, %Flop.Meta{}} =
      queryable
      |> Flop.validate_and_run!(map_or_flop, opts)

    result
  end

  @doc """
  Prepare `:filters` opt to be used as a Flop filter

  ## Examples

      iex> opts = [filters: [a: "a", b: ["b"], c: "c"]]
      iex> fields_and_ops = [a: :==, b: :in]
      iex> build_flop_filters_param(opts, fields_and_ops)
      [[field: :a, op: :==, value: "a"], [field: :b, op: :in value: ["b"]]]
  """
  def build_flop_filters_param(opts \\ [], fields_and_ops \\ []) do
    case Keyword.get(opts, :filters) do
      filters when is_list(filters) ->
        Enum.reduce(
          filters,
          [],
          fn kv, filters ->
            reduce_filters_param(kv, filters, fields_and_ops)
          end
        )

      _ ->
        []
    end
  end

  defp reduce_filters_param({field, value}, filters, fields_and_ops) do
    if field in Keyword.keys(fields_and_ops) do
      [
        %{
          field: field,
          op: Keyword.get(fields_and_ops, field),
          value: value
        }
        | filters
      ]
    else
      filters
    end
  end

  defp reduce_filters_param(_, filters, _fields_and_ops), do: filters

  @doc """
  Create naive timestamps.
  To be used in `inserted_at` and `updated_at`.
  """
  def naive_timestamp() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end
end
