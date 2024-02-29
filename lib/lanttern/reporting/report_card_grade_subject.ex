defmodule Lanttern.Reporting.ReportCardGradeSubject do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

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
    |> unique_constraint(:subject_id,
      name: "report_card_grades_subjects_report_card_id_subject_id_index",
      message: gettext("Subject already added to this report card grades report")
    )
  end
end
