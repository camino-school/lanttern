defmodule Lanttern.ColorUtilsTest do
  use ExUnit.Case, async: true

  alias Lanttern.ColorUtils

  @scale %{
    start: 0.0,
    stop: 10.0,
    start_bg_color: "#000000",
    start_text_color: "#ffffff",
    stop_bg_color: "#ffffff",
    stop_text_color: "#000000"
  }

  describe "interpolate_numeric_scale_colors/2" do
    test "returns hex strings for mid-range score" do
      assert {bg, text} = ColorUtils.interpolate_numeric_scale_colors(@scale, 5.0)
      assert String.match?(bg, ~r/^#[0-9a-f]{6}$/i)
      assert String.match?(text, ~r/^#[0-9a-f]{6}$/i)
    end

    test "score at start returns start colors" do
      assert {"#000000", "#ffffff"} = ColorUtils.interpolate_numeric_scale_colors(@scale, 0.0)
    end

    test "score at stop returns stop colors" do
      assert {"#ffffff", "#000000"} = ColorUtils.interpolate_numeric_scale_colors(@scale, 10.0)
    end

    test "score below range is clamped to start" do
      assert ColorUtils.interpolate_numeric_scale_colors(@scale, -5.0) ==
               ColorUtils.interpolate_numeric_scale_colors(@scale, 0.0)
    end

    test "score above range is clamped to stop" do
      assert ColorUtils.interpolate_numeric_scale_colors(@scale, 15.0) ==
               ColorUtils.interpolate_numeric_scale_colors(@scale, 10.0)
    end

    test "returns {bg, nil} when only bg colors are present" do
      scale = %{start: 0.0, stop: 10.0, start_bg_color: "#000000", stop_bg_color: "#ffffff"}
      assert {bg, nil} = ColorUtils.interpolate_numeric_scale_colors(scale, 5.0)
      assert String.match?(bg, ~r/^#[0-9a-f]{6}$/i)
    end

    test "returns {nil, text} when only text colors are present" do
      scale = %{start: 0.0, stop: 10.0, start_text_color: "#000000", stop_text_color: "#ffffff"}
      assert {nil, text} = ColorUtils.interpolate_numeric_scale_colors(scale, 5.0)
      assert String.match?(text, ~r/^#[0-9a-f]{6}$/i)
    end

    test "returns nil when scale has no color fields" do
      assert ColorUtils.interpolate_numeric_scale_colors(%{start: 0.0, stop: 10.0}, 5.0) == nil
    end

    test "handles degenerate scale where start equals stop" do
      degenerate = %{@scale | stop: 0.0}
      assert {"#000000", _} = ColorUtils.interpolate_numeric_scale_colors(degenerate, 0.0)
    end
  end
end
