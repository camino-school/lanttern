defmodule Lanttern.LessonFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_factory(attrs) do
        strand = Map.get(attrs, :strand, build(:strand))

        lesson =
          %Lanttern.Lessons.Lesson{
            name: "Lesson",
            position: 0,
            strand: strand
          }

        lesson
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
