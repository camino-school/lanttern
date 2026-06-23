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

  @doc """
  Formats a float for display, removing `.0` suffix (showing as integer)
  and removing trailing zeros from decimal places.
  """
  def format_float(float) do
    float
    |> Float.to_string()
    |> String.replace(~r/\.0$|(?<=\.\d)0+$/, "")
  end

  @doc """
  Formats a normalized value (0.0–1.0) for display, floored to 2 decimals.

  Floors — never rounds. Normalized values feed pass/fail (and ordinal band)
  decisions, so displaying a value greater than the real one is misleading:
  rounding `0.599` up to `"0.60"` can read as meeting a `0.60` threshold the
  student did not actually reach. Flooring guarantees the shown value is never
  above the real one and keeps every normalized-value display (scale bars,
  composition tables, entry overlays) consistent.

  Returns `"—"` for `nil`.
  """
  def format_normalized(nil), do: "—"

  def format_normalized(value) do
    (value * 1.0)
    |> Decimal.from_float()
    |> Decimal.round(2, :floor)
    |> Decimal.to_string()
  end
end
