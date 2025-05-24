defmodule Lanttern.ILPSectionFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_section_factory do
        %Lanttern.ILP.ILPSection{
          name: sequence("ilp_section"),
          position: 1,
        }
      end
    end
  end
end
