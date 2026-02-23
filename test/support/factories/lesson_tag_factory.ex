defmodule Lanttern.LessonTagFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_tag_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.Lessons.Tag{
          name: "some tag name",
          bg_color: "#aabbcc",
          text_color: "#112233",
          position: 0,
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
