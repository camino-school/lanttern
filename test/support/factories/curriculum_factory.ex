defmodule Lanttern.CurriculumFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def curriculum_factory(attrs) do
        school =
          if Map.has_key?(attrs, :school_id) do
            nil
          else
            Map.get(attrs, :school, build(:school))
          end

        base = %Lanttern.Curricula.Curriculum{
          name: "Some curriculum",
          code: Ecto.UUID.generate()
        }

        base =
          if school do
            %{base | school: school}
          else
            base
          end

        base
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
