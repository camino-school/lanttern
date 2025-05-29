defmodule Lanttern.MessageBoardFactory do
  @moduledoc """
  Factory for the MessageBoard schema.
  This factory is used to create instances of the MessageBoard schema for testing purposes.
  It provides a default set of attributes for the MessageBoard schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def message_board_factory do
        %Lanttern.MessageBoard.Message{
          description: "some description",
          name: "some name",
          send_to: "school",
          school: build(:school)
        }
      end
    end
  end
end
