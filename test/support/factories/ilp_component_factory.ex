defmodule Lanttern.ILPComponentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_component_factory(attrs) do
        template = Map.get(attrs, :template, build(:ilp_template))
        section = Map.get(attrs, :section, build(:ilp_section, template: template))

        component =
          %Lanttern.ILP.ILPComponent{
            name: sequence("ilp_component"),
            position: 1,
            template: template,
            section: section
          }

        component
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
