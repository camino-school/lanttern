defmodule Lanttern.ReportCardFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def report_card_factory(attrs) do
        school_cycle = Map.get(attrs, :school_cycle, build(:cycle))
        year = Map.get(attrs, :year, build(:year))

        %Lanttern.Reporting.ReportCard{
          name: "Report Card",
          school_cycle: school_cycle,
          year: year
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
