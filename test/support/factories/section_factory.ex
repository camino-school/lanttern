defmodule Lanttern.SectionFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def section_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        section =
          %Lanttern.MessageBoard.Section{
            name: "Section Name",
            position: 0,
            school: school
          }

        section
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
