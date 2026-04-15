defmodule Lanttern.CurriculumComponentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def curriculum_component_factory(attrs) do
        school =
          if Map.has_key?(attrs, :school_id) do
            nil
          else
            Map.get(attrs, :school, build(:school))
          end

        curriculum =
          cond do
            Map.has_key?(attrs, :curriculum_id) ->
              nil

            Map.has_key?(attrs, :curriculum) ->
              attrs.curriculum

            school ->
              build(:curriculum, school: school)

            true ->
              build(:curriculum, school_id: attrs[:school_id])
          end

        base = %Lanttern.Curricula.CurriculumComponent{
          name: Ecto.UUID.generate(),
          code: Ecto.UUID.generate()
        }

        base =
          if school, do: %{base | school: school}, else: base

        base =
          if curriculum, do: %{base | curriculum: curriculum}, else: base

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
