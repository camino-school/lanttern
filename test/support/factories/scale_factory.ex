defmodule Lanttern.ScaleFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def scale_factory(attrs) do
        school =
          if Map.has_key?(attrs, :school_id) do
            nil
          else
            Map.get(attrs, :school, build(:school))
          end

        base = %Lanttern.Grading.Scale{
          name: "Scale",
          type: "numeric",
          start: 0.0,
          stop: 100.0,
          breakpoints: []
        }

        base =
          if school do
            %{base | school: school}
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
