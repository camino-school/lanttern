defmodule Lanttern.CurriculumItemFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def curriculum_item_factory(attrs) do
        school =
          if Map.has_key?(attrs, :school_id) do
            nil
          else
            Map.get(attrs, :school, build(:school))
          end

        curriculum_component =
          cond do
            Map.has_key?(attrs, :curriculum_component_id) ->
              nil

            Map.has_key?(attrs, :curriculum_component) ->
              attrs.curriculum_component

            school ->
              build(:curriculum_component, school: school)

            true ->
              build(:curriculum_component, school_id: attrs[:school_id])
          end

        base = %Lanttern.Curricula.CurriculumItem{
          name: Ecto.UUID.generate(),
          code: Ecto.UUID.generate()
        }

        base =
          if school, do: %{base | school: school}, else: base

        base =
          if curriculum_component,
            do: %{base | curriculum_component: curriculum_component},
            else: base

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
