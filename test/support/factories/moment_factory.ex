defmodule Lanttern.MomentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def moment_factory(attrs) do
        strand = Map.get(attrs, :strand, build(:strand))

        moment =
          %Lanttern.LearningContext.Moment{
            name: "Moment",
            description: "Moment description",
            position: 0,
            strand: strand
          }

        moment
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
