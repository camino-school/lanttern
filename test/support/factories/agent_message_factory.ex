defmodule Lanttern.AgentMessageFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def agent_message_factory(attrs) do
        conversation = Map.get(attrs, :conversation, build(:conversation))

        message =
          %Lanttern.AgentChat.Message{
            role: "user",
            content: "Hello, how can you help me today?",
            conversation: conversation
          }

        message
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
