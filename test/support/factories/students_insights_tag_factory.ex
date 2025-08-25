defmodule Lanttern.StudentInsightTagFactory do
  @moduledoc """
  Factory for the StudentsInsights.Tag schema.
  This factory is used to create instances of the StudentsInsights.Tag schema for testing purposes.
  """
  defmacro __using__(_opts) do
    quote do
      def student_insight_tag_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.StudentsInsights.Tag{
          name: "Important",
          bg_color: "#ff0000",
          text_color: "#ffffff",
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
