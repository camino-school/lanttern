defmodule Lanttern.ClassAssignmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def class_assignment_factory(attrs) do
        school = Map.get(attrs, :school, insert(:school))
        strand = Map.get(attrs, :strand, build(:strand))
        class = Map.get(attrs, :class, build(:class, school: school))

        attrs = Map.drop(attrs, [:school])

        %Lanttern.Strands.ClassAssignment{
          strand: strand,
          class: class
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
