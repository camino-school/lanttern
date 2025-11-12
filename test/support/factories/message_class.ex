defmodule Lanttern.MessageClassFactory do
  @moduledoc """
  Factory for the MessageClass schema.
  """

  defmacro __using__(_opts) do
    quote do
      def message_class_factory do
        %Lanttern.MessageBoard.MessageClass{
          message: nil,
          class: nil,
          school: nil
        }
      end
    end
  end
end
