defmodule Lanttern.ILPEntryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_entry_factory(attrs) do
        template = Map.get(attrs, :template, build(:ilp_template))
        component = Map.get(attrs, :component, build(:ilp_component, template: template))
        student_ilp = Map.get(attrs, :student_ilp, build(:student_ilp, template: template))

        entry =
          %Lanttern.ILP.ILPEntry{
            description: sequence("ilp entry description"),
            template: template,
            component: component,
            student_ilp: student_ilp
          }

        entry
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
