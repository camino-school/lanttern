defmodule Lanttern.LessonCurriculumItemFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_curriculum_item_factory(attrs) do
        lesson = Map.get(attrs, :lesson, build(:lesson))
        curriculum_item = Map.get(attrs, :curriculum_item, build(:curriculum_item))

        %Lanttern.Lessons.LessonCurriculumItem{
          position: 0,
          lesson: lesson,
          curriculum_item: curriculum_item
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
