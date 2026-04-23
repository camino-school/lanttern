defmodule Lanttern.ColorUtils do
  @moduledoc """
  Pure color utility functions.
  """

  @doc """
  Interpolates bg and text colors for a numeric scale score using LAB color
  space for perceptually uniform blending.

  Each color pair (bg and text) is computed independently:
  - If both `start_bg_color` and `stop_bg_color` are present, bg is interpolated; otherwise `nil`.
  - If both `start_text_color` and `stop_text_color` are present, text is interpolated; otherwise `nil`.

  Returns `{bg_color | nil, text_color | nil}` when at least one color pair is present,
  or `nil` when the scale has no usable color fields at all.

  Scores outside `[start, stop]` are clamped to the boundary.
  """
  @spec interpolate_numeric_scale_colors(map(), float()) ::
          {String.t() | nil, String.t() | nil} | nil
  def interpolate_numeric_scale_colors(%{start: range_start, stop: range_stop} = scale, score) do
    t = compute_t(score, range_start, range_stop)

    bg =
      case scale do
        %{start_bg_color: s, stop_bg_color: e} when is_binary(s) and is_binary(e) ->
          lab_interpolate_hex(s, e, t)

        _ ->
          nil
      end

    text =
      case scale do
        %{start_text_color: s, stop_text_color: e} when is_binary(s) and is_binary(e) ->
          lab_interpolate_hex(s, e, t)

        _ ->
          nil
      end

    if is_nil(bg) and is_nil(text), do: nil, else: {bg, text}
  end

  def interpolate_numeric_scale_colors(_scale, _score), do: nil

  # Normalized position t ∈ [0.0, 1.0]; clamps out-of-range scores.
  # Handles degenerate case where start == stop to avoid division by zero.
  defp compute_t(_score, same, same), do: 0.0

  defp compute_t(score, range_start, range_stop) do
    score
    |> max(range_start)
    |> min(range_stop)
    |> then(&((&1 - range_start) / (range_stop - range_start)))
  end

  # Interpolates two hex colors in LAB space at weight t; returns lowercase hex string.
  defp lab_interpolate_hex(hex_start, hex_stop, t) do
    lab_start = hex_start |> Colorex.parse!() |> Colorex.lab()
    lab_stop = hex_stop |> Colorex.parse!() |> Colorex.lab()

    %Colorex.LAB{
      l: lerp(lab_start.l, lab_stop.l, t),
      a: lerp(lab_start.a, lab_stop.a, t),
      b: lerp(lab_start.b, lab_stop.b, t),
      alpha: 1.0
    }
    |> to_string()
    |> String.downcase()
  end

  defp lerp(a, b, t), do: a + t * (b - a)
end
