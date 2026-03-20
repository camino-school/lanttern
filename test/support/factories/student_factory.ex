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

        base = %Lanttern.Schools.Student{
          name: sequence(:name, &"Student #{&1}")
        }

        base =
          if school do
            %{base | school: school, school_id: school.id}
          else
            base
          end

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
