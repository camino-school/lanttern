defmodule Lanttern.MessageFactory do
  @moduledoc """
  Factory for the Message schema.
  """

  defmacro __using__(_opts) do
    quote do
      def message_factory do
        %Lanttern.MessageBoard.Message{
          description: "some description",
          section: build(:section),
          name: sequence(:name, &"name-#{&1}"),
          send_to: "school",
          school: build(:school)
        }
      end
    end
  end
end
