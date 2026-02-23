defmodule Lanttern.AgentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def agent_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        agent =
          %Lanttern.Agents.Agent{
            name: "AI Agent",
            instructions: "some instructions",
            knowledge: "some knowledge",
            personality: "some personality",
            guardrails: "some guardrails",
            school: school
          }

        agent
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
