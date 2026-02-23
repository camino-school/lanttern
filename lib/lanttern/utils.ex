defmodule Lanttern.Utils do
  @moduledoc """
  Collection of utils functions.
  """

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
  Changes a list item position, based on the given indexes.
  """
  def reorder(list, cur_i, new_i) do
    {item, rest} = List.pop_at(list, cur_i)
    List.insert_at(rest, new_i, item)
  end
end
