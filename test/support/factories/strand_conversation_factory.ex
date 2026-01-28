defmodule Lanttern.StrandConversationFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def strand_conversation_factory(attrs) do
        conversation = Map.get(attrs, :conversation, build(:conversation))
        strand = Map.get(attrs, :strand, build(:strand))
        lesson = Map.get(attrs, :lesson)

        strand_conversation =
          %Lanttern.AgentChat.StrandConversation{
            conversation: conversation,
            strand: strand,
            lesson: lesson
          }

        strand_conversation
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
