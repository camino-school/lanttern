defmodule Lanttern.GradesReports.GradesReportSubject do
  @moduledoc """
  The `GradesReportSubject` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.Taxonomy.Subject

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          subject: Subject.t(),
          subject_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grades_report_subjects" do
    field :position, :integer, default: 0

    belongs_to :subject, Subject
    belongs_to :grades_report, GradesReport

    timestamps()
  end

  @doc false
  def changeset(grades_report_subject, attrs) do
    grades_report_subject
    |> cast(attrs, [:position, :subject_id, :grades_report_id])
    |> validate_required([:subject_id, :grades_report_id])
    |> unique_constraint(:subject_id,
      name: "grades_report_subjects_grades_report_id_subject_id_index",
      message: gettext("Cycle already added to this grade report")
    )
  end
end
