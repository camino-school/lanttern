defmodule Lanttern.StrandCurriculumItemFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def strand_curriculum_item_factory(attrs) do
        strand = Map.get(attrs, :strand, build(:strand))
        curriculum_item = Map.get(attrs, :curriculum_item, build(:curriculum_item))

        %Lanttern.Strands.StrandCurriculumItem{
          position: 0,
          strand: strand,
          curriculum_item: curriculum_item
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
