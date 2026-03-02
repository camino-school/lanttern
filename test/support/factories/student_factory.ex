defmodule Lanttern.StudentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.Schools.Student{
          name: "John Doe",
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
        |> then(fn student ->
          if Map.has_key?(attrs, :school_id) do
            %{student | school: nil}
          else
            student
          end
        end)
      end
    end
  end
end
