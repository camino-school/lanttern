defmodule Lanttern.LessonLogFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def lesson_log_factory(attrs) do
        strand = Map.get(attrs, :strand, build(:strand))
        profile = Map.get(attrs, :profile, build(:profile))
        lesson = Map.get(attrs, :lesson, build(:lesson, strand: strand))

        lesson_log =
          %Lanttern.Lessons.LessonLog{
            lesson_id: lesson.id,
            profile_id: profile.id,
            operation: "CREATE",
            name: "Lesson",
            position: 0,
            strand_id: strand.id,
            is_published: false,
            is_ai_agent: false
          }

        lesson_log
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
