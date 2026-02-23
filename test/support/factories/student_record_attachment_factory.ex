defmodule Lanttern.StudentRecordAttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_record_attachment_factory(attrs) do
        attachment = Map.get(attrs, :attachment, build(:attachment))
        student_record = Map.get(attrs, :student_record, build(:student_record))

        %Lanttern.StudentsRecords.StudentRecordAttachment{
          attachment: attachment,
          student_record: student_record,
          position: 0
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
