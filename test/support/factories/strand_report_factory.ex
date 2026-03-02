defmodule Lanttern.StrandReportFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def strand_report_factory(attrs) do
        report_card = Map.get(attrs, :report_card, build(:report_card))
        strand = Map.get(attrs, :strand, build(:strand))

        %Lanttern.Reporting.StrandReport{
          report_card: report_card,
          strand: strand
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
