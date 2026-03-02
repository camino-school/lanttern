defmodule Lanttern.StudentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_factory(attrs) do
        # Only build school if not providing school_id directly
        school =
          if Map.has_key?(attrs, :school_id) do
            nil
          else
            Map.get(attrs, :school, build(:school))
          end

        %Lanttern.Schools.Student{
          name: "John Doe",
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
