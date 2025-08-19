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
  Normalizes map keys to atoms.

  Converts all string keys in a map to atom keys, leaving atom keys unchanged.
  Non-string, non-atom keys are left as-is.

  ## Examples

      iex> normalize_attrs_to_atom_keys(%{"name" => "John", "age" => 30})
      %{name: "John", age: 30}

      iex> normalize_attrs_to_atom_keys(%{name: "John", age: 30})
      %{name: "John", age: 30}

      iex> normalize_attrs_to_atom_keys(%{})
      %{}

  """
  def normalize_attrs_to_atom_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
  end
end
