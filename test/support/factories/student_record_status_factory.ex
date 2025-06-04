defmodule Lanttern.StudentRecordStatusFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_records_status_factory do
        %Lanttern.StudentsRecords.StudentRecordStatus{
          name: "Solved",
          position: 2,
          bg_color: "#111111",
          text_color: "#ffffff",
          is_closed: true,
          school: build(:school)
        }
      end
    end
  end
end
