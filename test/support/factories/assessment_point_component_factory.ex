defmodule Lanttern.AssessmentPointComponentFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def assessment_point_component_factory(attrs) do
        %Lanttern.AssessmentComposition.Component{
          weight: 1.0,
          parent: build(:assessment_point),
          component: build(:assessment_point)
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
