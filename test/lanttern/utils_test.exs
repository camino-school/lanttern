defmodule Lanttern.UtilsTest do
  use ExUnit.Case, async: true

  alias Lanttern.Utils

  describe "format_float/1" do
    test "removes .0 suffix for whole numbers" do
      assert Utils.format_float(10.0) == "10"
      assert Utils.format_float(100.0) == "100"
    end

    test "returns zero without decimal suffix" do
      assert Utils.format_float(0.0) == "0"
    end

    test "preserves meaningful decimal places" do
      assert Utils.format_float(1.5) == "1.5"
      assert Utils.format_float(1.25) == "1.25"
    end
  end
end
