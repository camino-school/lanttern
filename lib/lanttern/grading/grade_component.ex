defmodule Lanttern.Grading.GradeComponent do
  @moduledoc """
  The `GradeComponent` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.GradesReportCycle
  alias Lanttern.GradesReports.GradesReportSubject

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          weight: float(),
          assessment_point: AssessmentPoint.t(),
          assessment_point_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          grades_report_cycle: GradesReportCycle.t(),
          grades_report_cycle_id: pos_integer(),
          grades_report_subject: GradesReportSubject.t(),
          grades_report_subject_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grade_components" do
    field :position, :integer, default: 0
    field :weight, :float, default: 1.0

    belongs_to :assessment_point, AssessmentPoint
    belongs_to :grades_report, GradesReport
    belongs_to :grades_report_cycle, GradesReportCycle
    belongs_to :grades_report_subject, GradesReportSubject

    timestamps()
  end

  @doc false
  def changeset(grade_component, attrs) do
    grade_component
    |> cast(attrs, [
      :weight,
      :position,
      :assessment_point_id,
      :grades_report_id,
      :grades_report_cycle_id,
      :grades_report_subject_id
    ])
    |> validate_required([
      :weight,
      :position,
      :assessment_point_id,
      :grades_report_id,
      :grades_report_cycle_id,
      :grades_report_subject_id
    ])
  end
end
