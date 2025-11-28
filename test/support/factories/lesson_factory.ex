defmodule Lanttern.LessonFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_factory(attrs) do
        strand_id = Map.get(attrs, :strand_id, insert(:strand).id)

        lesson =
          %Lanttern.Lessons.Lesson{
            name: "Lesson",
            position: 0,
            strand_id: strand_id
          }

        lesson
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
