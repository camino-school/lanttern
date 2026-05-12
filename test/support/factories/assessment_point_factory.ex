defmodule Lanttern.AssessmentPointFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def assessment_point_factory(attrs) do
        %Lanttern.Assessments.AssessmentPoint{
          name: "Assessment Point",
          datetime: ~U[2025-01-01 08:00:00Z],
          scale: build(:scale),
          curriculum_item: build(:curriculum_item)
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
