defmodule Lanttern.GradesReports.StudentGradeReportEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Reporting.GradesReport
  alias Lanttern.Reporting.GradesReportCycle
  alias Lanttern.Reporting.GradesReportSubject
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          normalized_value: float(),
          score: float(),
          student: Student.t(),
          student_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          grades_report_cycle: GradesReportCycle.t(),
          grades_report_cycle_id: pos_integer(),
          grades_report_subject: GradesReportSubject.t(),
          grades_report_subject_id: pos_integer(),
          ordinal_value: OrdinalValue.t(),
          ordinal_value_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_grade_report_entries" do
    field :comment, :string
    field :normalized_value, :float
    field :score, :float

    belongs_to :student, Student
    belongs_to :grades_report, GradesReport
    belongs_to :grades_report_cycle, GradesReportCycle
    belongs_to :grades_report_subject, GradesReportSubject
    belongs_to :ordinal_value, OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(student_grade_report_entry, attrs) do
    student_grade_report_entry
    |> cast(attrs, [
      :comment,
      :normalized_value,
      :score,
      :student_id,
      :grades_report_id,
      :grades_report_cycle_id,
      :grades_report_subject_id,
      :ordinal_value_id
    ])
    |> validate_required([
      :normalized_value,
      :student_id,
      :grades_report_id,
      :grades_report_cycle_id,
      :grades_report_subject_id
    ])
  end
end
