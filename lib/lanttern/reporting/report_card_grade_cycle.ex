defmodule Lanttern.Reporting.ReportCardGradeCycle do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  schema "report_card_grades_cycles" do
    belongs_to :school_cycle, Lanttern.Schools.Cycle
    belongs_to :report_card, Lanttern.Reporting.ReportCard

    timestamps()
  end

  @doc false
  def changeset(report_card_grade_cycle, attrs) do
    report_card_grade_cycle
    |> cast(attrs, [:school_cycle_id, :report_card_id])
    |> validate_required([:school_cycle_id, :report_card_id])
    |> unique_constraint(:school_cycle_id,
      name: "report_card_grades_cycles_report_card_id_school_cycle_id_index",
      message: gettext("Cycle already added to this report card grades report")
    )
  end
end
