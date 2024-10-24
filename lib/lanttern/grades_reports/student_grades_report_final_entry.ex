defmodule Lanttern.GradesReports.StudentGradesReportFinalEntry do
  @moduledoc """
  The `StudentGradesReportFinalEntry` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.GradesReportSubject
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          score: float(),
          pre_retake_score: float(),
          student: Student.t(),
          student_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          grades_report_subject: GradesReportSubject.t(),
          grades_report_subject_id: pos_integer(),
          ordinal_value: OrdinalValue.t(),
          ordinal_value_id: pos_integer(),
          pre_retake_ordinal_value: OrdinalValue.t(),
          pre_retake_ordinal_value_id: pos_integer(),
          composition_normalized_value: float(),
          composition_ordinal_value: OrdinalValue.t(),
          composition_ordinal_value_id: pos_integer(),
          composition_score: float(),
          composition_datetime: DateTime.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_grades_reports_final_entries" do
    field :comment, :string
    field :score, :float
    field :pre_retake_score, :float

    belongs_to :student, Student
    belongs_to :grades_report, GradesReport
    belongs_to :grades_report_subject, GradesReportSubject
    belongs_to :ordinal_value, OrdinalValue
    belongs_to :pre_retake_ordinal_value, OrdinalValue

    # composition related fields
    field :composition_normalized_value, :float
    belongs_to :composition_ordinal_value, OrdinalValue
    field :composition_score, :float
    field :composition_datetime, :utc_datetime

    embeds_many :composition, CompositionComponent, on_replace: :delete, primary_key: false do
      field :school_cycle_id, :id
      field :school_cycle_name, :string

      field :ordinal_value_id, :id
      field :ordinal_value_name, :string
      field :score, :float

      field :normalized_value, :float
      field :weight, :float
    end

    timestamps()
  end

  @doc false
  def changeset(student_grades_report_entry, attrs) do
    student_grades_report_entry
    |> cast(attrs, [
      :comment,
      :score,
      :pre_retake_score,
      :student_id,
      :grades_report_id,
      :grades_report_subject_id,
      :ordinal_value_id,
      :pre_retake_ordinal_value_id,
      :composition_normalized_value,
      :composition_ordinal_value_id,
      :composition_score,
      :composition_datetime
    ])
    |> validate_required([
      :student_id,
      :grades_report_id,
      :grades_report_subject_id,
      :composition_normalized_value
    ])
    |> cast_embed(:composition, with: &composition_component_changeset/2)
  end

  defp composition_component_changeset(schema, params) do
    schema
    |> cast(params, [
      :school_cycle_id,
      :school_cycle_name,
      :ordinal_value_id,
      :ordinal_value_name,
      :score,
      :normalized_value,
      :weight
    ])
  end
end
