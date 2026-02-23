defmodule Lanttern.ConversationFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def conversation_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))
        profile = Map.get(attrs, :profile, build(:profile))

        conversation =
          %Lanttern.AgentChat.Conversation{
            name: "Conversation about learning",
            profile: profile,
            school: school
          }

        conversation
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
