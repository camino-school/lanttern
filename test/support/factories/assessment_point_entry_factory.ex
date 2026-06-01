defmodule Lanttern.AssessmentPointEntryFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def assessment_point_entry_factory(attrs) do
        scale = Map.get_lazy(attrs, :scale, fn -> build(:scale) end)

        assessment_point =
          Map.get_lazy(attrs, :assessment_point, fn -> build(:assessment_point, scale: scale) end)

        %Lanttern.Assessments.AssessmentPointEntry{
          assessment_point: assessment_point,
          student: build(:student),
          scale: scale,
          scale_type: scale.type
        }
        |> merge_attributes(Map.drop(attrs, [:scale, :assessment_point]))
        |> evaluate_lazy_attributes()
      end
    end
  end
end
