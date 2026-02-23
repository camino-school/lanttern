defmodule Lanttern.LessonAttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def lesson_attachment_factory(attrs) do
        attachment = Map.get(attrs, :attachment, build(:attachment))
        lesson = Map.get(attrs, :lesson, build(:lesson))

        lesson_attachment =
          %Lanttern.Lessons.LessonAttachment{
            attachment: attachment,
            lesson: lesson,
            position: 0,
            is_teacher_only_resource: true
          }

        lesson_attachment
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
