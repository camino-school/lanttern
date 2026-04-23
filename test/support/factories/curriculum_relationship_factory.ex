defmodule Lanttern.CurriculumRelationshipFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def curriculum_relationship_factory(attrs) do
        curriculum_item_a =
          if Map.has_key?(attrs, :curriculum_item_a_id) do
            nil
          else
            Map.get(attrs, :curriculum_item_a, build(:curriculum_item))
          end

        curriculum_item_b =
          if Map.has_key?(attrs, :curriculum_item_b_id) do
            nil
          else
            Map.get(attrs, :curriculum_item_b, build(:curriculum_item))
          end

        base = %Lanttern.Curricula.CurriculumRelationship{
          type: "cross"
        }

        base =
          if curriculum_item_a,
            do: %{base | curriculum_item_a: curriculum_item_a},
            else: base

        base =
          if curriculum_item_b,
            do: %{base | curriculum_item_b: curriculum_item_b},
            else: base

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
