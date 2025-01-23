defmodule Lanttern.RepoHelpers do
  @moduledoc """
  Helpers related to `Repo`
  """

  alias Lanttern.Repo
  import Ecto.Query, only: [from: 2]

  use Gettext, backend: Lanttern.Gettext

  defmodule Page do
    @moduledoc "General pagination page struct and related utils"

    @type t() :: %__MODULE__{
            results: list(),
            has_next: boolean(),
            keyset: any()
          }

    @typedoc """
    The `opts` spec to use in pagination functions.

    When fetching `first` results, the query should include `first + 1` results
    (the extra result should be handled by `extract_pagination_fields_from/3`).
    """
    @type opts() :: [first: pos_integer(), after: Keyword.t() | nil]

    @typedoc """
    The function to use as the last arg in `extract_pagination_fields_from/3`.

    This function will receive the last item of results as arg, and should
    return the pagination query keyset (a `Keyword.t()`) to be used as `after` opt.
    """
    @type keyset_fn() :: (last :: any() -> Keyword.t())

    defstruct [:keyset, results: [], has_next: false]

    @doc """
    Util function to extract `results`, `has_next`, and `keyset` from a given list.

    It will:

    1. remove the last result from the list, if needed
    2. determine if `Page.has_next`
    3. extract the keyset from the last result based on given `keyset_fn`
    """
    @spec extract_pagination_fields_from(
            list(),
            first :: pos_integer(),
            keyset_fn :: keyset_fn()
          ) ::
            {results :: list(), has_next :: boolean(), keyset :: Keyword.t() | nil}
    def extract_pagination_fields_from([], _, _),
      do: {[], false, nil}

    def extract_pagination_fields_from([single], _, _),
      do: {[single], false, nil}

    def extract_pagination_fields_from(list, first, keyset_fn) do
      if length(list) > first do
        {_, results} = List.pop_at(list, -1)
        keyset = Enum.at(results, -1) |> keyset_fn.()

        {results, true, keyset}
      else
        {list, false, nil}
      end
    end
  end

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

  Skip if position already present in attrs.
  """
  @spec set_position_in_attrs(Ecto.Queryable.t(), attrs :: map()) :: map()
  def set_position_in_attrs(_queryable, %{position: position} = attrs) when is_integer(position),
    do: attrs

  def set_position_in_attrs(_queryable, %{"position" => position} = attrs)
      when is_integer(position),
      do: attrs

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

  @doc """
  Update schema positions based on ids list order.

  ## Options

  - `:id_field` - used change the column used to compare with the list of ids. defaults to `:id`

  ## Examples

      iex> update_positions(queryable, [3, 2, 1])
      :ok

  """
  @spec update_positions(Ecto.Queryable.t(), [pos_integer()], Keyword.t()) ::
          :ok | {:error, String.t()}
  def update_positions(queryable, ids, opts \\ []) do
    ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        filter = [{Keyword.get(opts, :id_field, :id), id}]

        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            q in queryable,
            where: ^filter
          ),
          set: [position: i]
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} -> :ok
      _ -> {:error, gettext("Something went wrong")}
    end
  end
end
