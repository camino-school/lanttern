defmodule Lanttern.StudentRecordRelationshipFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_record_relationship_factory do
        %Lanttern.StudentsRecords.StudentRecordRelationship{
          # student_record_id: student_record.id,
          # school_id: school.id,
          # student_id: student.id,
        }
      end
    end
  end
end
