defmodule Lanttern.Reporting.StudentReportCard do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  schema "student_report_cards" do
    field :comment, :string
    field :footnote, :string

    belongs_to :report_card, Lanttern.Reporting.ReportCard
    belongs_to :student, Lanttern.Schools.Student

    timestamps()
  end

  @doc false
  def changeset(student_report_card, attrs) do
    student_report_card
    |> cast(attrs, [:comment, :footnote, :report_card_id, :student_id])
    |> validate_required([:report_card_id, :student_id])
    |> unique_constraint([:student_id, :report_card_id],
      message: gettext("Student already linked to report card")
    )
  end
end
