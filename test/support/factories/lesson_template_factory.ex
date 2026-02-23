defmodule Lanttern.LessonTemplateFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_template_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        lesson_template =
          %Lanttern.LessonTemplates.LessonTemplate{
            name: "Lesson template",
            about: "About template",
            template: "Template",
            school: school
          }

        lesson_template
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
