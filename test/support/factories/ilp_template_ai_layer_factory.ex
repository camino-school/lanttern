defmodule Lanttern.ILPTemplateAILayerFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_template_ai_layer_factory(attrs) do
        template = Map.get(attrs, :template, build(:ilp_template))

        ai_layer =
          %Lanttern.ILP.ILPTemplateAILayer{
            revision_instructions: "some revision instructions",
            model: nil,
            cooldown_minutes: 0,
            template: template
          }

        ai_layer
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
