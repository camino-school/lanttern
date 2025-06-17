defmodule Lanttern.ILPTemplateFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_template_factory do
        %Lanttern.ILP.ILPTemplate{
          name: sequence(:name, &"ILP Template #-#{&1}")
          # school: build(:school)
        }
      end
    end
  end
end
