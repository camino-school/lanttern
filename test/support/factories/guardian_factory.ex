defmodule Lanttern.GuardianFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def guardian_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.Schools.Guardian{
          name: "Jane Guardian",
          school: school
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
