defmodule Lanttern.Grading.GradeComponent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Taxonomy.Subject

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          weight: float(),
          report_card: ReportCard.t(),
          report_card_id: pos_integer(),
          assessment_point: AssessmentPoint.t(),
          assessment_point_id: pos_integer(),
          subject: Subject.t(),
          subject_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grade_components" do
    field :position, :integer, default: 0
    field :weight, :float, default: 1.0

    belongs_to :report_card, ReportCard
    belongs_to :assessment_point, AssessmentPoint
    belongs_to :subject, Subject

    timestamps()
  end

  @doc false
  def changeset(grade_component, attrs) do
    grade_component
    |> cast(attrs, [:weight, :position, :report_card_id, :assessment_point_id, :subject_id])
    |> validate_required([:weight, :position, :report_card_id, :assessment_point_id, :subject_id])
  end
end
