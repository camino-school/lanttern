defmodule Lanttern.Reporting.ReportCardGradeSubject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "report_card_grades_subjects" do
    field :position, :integer, default: 0

    belongs_to :subject, Lanttern.Taxonomy.Subject
    belongs_to :report_card, Lanttern.Reporting.ReportCard

    timestamps()
  end

  @doc false
  def changeset(report_card_grade_subject, attrs) do
    report_card_grade_subject
    |> cast(attrs, [:position, :subject_id, :report_card_id])
    |> validate_required([:subject_id, :report_card_id])
  end
end
