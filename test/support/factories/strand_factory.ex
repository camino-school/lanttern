defmodule Lanttern.StrandFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def strand_factory(attrs) do
        strand =
          %Lanttern.LearningContext.Strand{
            name: "Strand",
            description: "Strand description"
          }

        strand
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
