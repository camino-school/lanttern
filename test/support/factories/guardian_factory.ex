defmodule Lanttern.GuardianFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def guardian_factory(attrs) do
        # Only build school if neither school nor school_id is provided
        school =
          cond do
            Map.has_key?(attrs, :school) -> Map.get(attrs, :school)
            Map.has_key?(attrs, :school_id) -> nil
            true -> build(:school)
          end

        guardian =
          if school do
            %Lanttern.Schools.Guardian{
              name: "Jane Guardian",
              school: school
            }
          else
            %Lanttern.Schools.Guardian{
              name: "Jane Guardian"
            }
          end

        guardian
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
