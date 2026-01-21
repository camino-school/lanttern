defmodule Lanttern.ModelCallFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def model_call_factory(attrs) do
        message = Map.get(attrs, :message, build(:agent_message))

        model_call =
          %Lanttern.AgentChat.ModelCall{
            prompt_tokens: 10,
            completion_tokens: 20,
            model: "gpt-5-nano",
            message: message
          }

        model_call
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
