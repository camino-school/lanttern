defmodule Lanttern.Utils do
  @moduledoc """
  Collection of utils functions.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  import LantternWeb.Gettext

  @doc """
  Swaps two items in a list, based on the given indexes.

  From https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  """
  def swap(list, i1, i2) do
    e1 = Enum.at(list, i1)
    e2 = Enum.at(list, i2)

    list
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end

  @doc """
  Update schema positions based on ids list order.

  ## Examples

      iex> update_positions(queryable, [3, 2, 1])
      :ok

  """
  @spec update_positions(Ecto.Queryable.t(), [integer()]) :: :ok | {:error, String.t()}
  def update_positions(queryable, ids) do
    ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            q in queryable,
            where: q.id == ^id
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
