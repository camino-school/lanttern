defmodule Lanttern.MessageBoardFactory do
  @moduledoc """
  Factory for the MessageBoard schema.
  This factory is used to create instances of the MessageBoard schema for testing purposes.
  It provides a default set of attributes for the MessageBoard schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def message_factory do
        %Lanttern.MessageBoard.Message{
          description: "some description",
          section: sequence(:section, &"section-#{&1}"),
          name: sequence(:name, &"name-#{&1}"),
          send_to: "school",
          school: build(:school)
        }
      end
    end
  end
end
