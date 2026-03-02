defmodule Lanttern.YearFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def year_factory(attrs) do
        %Lanttern.Taxonomy.Year{
          name: "Year"
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
