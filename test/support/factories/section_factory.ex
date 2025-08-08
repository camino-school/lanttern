defmodule Lanttern.SectionFactory do
  @moduledoc """
  Factory for the Section schema.
  This factory is used to create instances of the Section schema for testing purposes.
  It provides a default set of attributes for the Section schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def section_factory do
        %Lanttern.MessageBoard.Section{
          name: sequence(:section_name, &"Section #{&1}"),
          position: 0
        }
      end
    end
  end
end
