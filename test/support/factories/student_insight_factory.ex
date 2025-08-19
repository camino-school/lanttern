defmodule Lanttern.StudentInsightFactory do
  @moduledoc """
  Factory for the StudentInsight schema.
  This factory is used to create instances of the StudentInsight schema for testing purposes.
  """
  defmacro __using__(_opts) do
    quote do
      def student_insight_factory(attrs) do
        school = Map.get(attrs, :school, insert(:school))
        author = Map.get(attrs, :author, build(:staff_member, %{school: school}))

        %Lanttern.StudentsInsights.StudentInsight{
          description: "This student learns better with visual aids and structured activities",
          author: author,
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
