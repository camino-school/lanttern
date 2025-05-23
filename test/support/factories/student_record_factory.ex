defmodule Lanttern.StudentRecordFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_record_factory do
        %Lanttern.StudentsRecords.StudentRecord{
          description: "Student record desc",
          date: ~N[2025-05-19 14:00:00],
          school: build(:school),
          # created_by_staff_member_id: 2,
          status_id: 3
        }
      end
    end
  end
end
