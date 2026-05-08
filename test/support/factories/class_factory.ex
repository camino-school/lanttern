defmodule Lanttern.ClassFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def class_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))
        cycle = Map.get(attrs, :cycle, build(:cycle, school: school))

        class =
          %Lanttern.Schools.Class{
            name: sequence(:name, &"Class-#{&1}"),
            school: school,
            cycle: cycle
          }

        class
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end

      def after_build(class, %{years: years}) when is_list(years) do
        %{class | years: years}
      end
    end
  end
end
