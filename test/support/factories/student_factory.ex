defmodule Lanttern.StudentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_factory do
        %Lanttern.Schools.Student{
          name: "John Doe",
          school: build(:school)
        }
      end
    end
  end
end
