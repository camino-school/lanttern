defmodule Lanttern.StudentReportCardFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_report_card_factory(attrs) do
        report_card = Map.get(attrs, :report_card, build(:report_card))
        student = Map.get(attrs, :student, build(:student))

        %Lanttern.Reporting.StudentReportCard{
          report_card: report_card,
          student: student
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
