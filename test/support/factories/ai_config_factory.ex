defmodule Lanttern.AiConfigFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ai_config_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.SchoolConfig.AiConfig{
          base_model: "gpt-5-mini",
          knowledge: "Default school knowledge",
          guardrails: "Default guardrails",
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
