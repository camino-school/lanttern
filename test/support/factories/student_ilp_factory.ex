defmodule Lanttern.StudentILPFactory do
  @moduledoc """
  This module defines a factory for creating StudentILP structs for testing purposes.

  `template`, `student`, and `cycle` should all be associated with
  the same `%Lanttern.Schools.School{}` as the Student ILP itself.
  """
  defmacro __using__(_opts) do
    quote do
      def student_ilp_factory(attrs) do
        school = Map.get(attrs, :school, insert(:school))
        template = Map.get(attrs, :template, build(:ilp_template, %{school: school}))
        student = Map.get(attrs, :student, build(:student, %{school: school}))
        cycle = Map.get(attrs, :cycle, build(:cycle, %{school: school}))

        student_ilp =
          %Lanttern.ILP.StudentILP{
            school: school,
            template: template,
            student: student,
            cycle: cycle
          }

        student_ilp
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
