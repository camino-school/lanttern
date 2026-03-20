defmodule Lanttern.OrdinalValueFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ordinal_value_factory(attrs) do
        scale =
          if Map.has_key?(attrs, :scale_id) do
            nil
          else
            Map.get(attrs, :scale, build(:scale))
          end

        base = %Lanttern.Grading.OrdinalValue{
          name: "Ordinal Value",
          normalized_value: 0.5,
          bg_color: "#000000",
          text_color: "#ffffff"
        }

        base =
          if scale do
            %{base | scale: scale}
          else
            base
          end

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
