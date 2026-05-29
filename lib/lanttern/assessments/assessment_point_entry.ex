defmodule Lanttern.Assessments.AssessmentPointEntry do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntryEvidence
  alias Lanttern.Attachments.Attachment
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          observation: String.t() | nil,
          report_note: String.t() | nil,
          student_report_note: String.t() | nil,
          score: float() | nil,
          student_score: float() | nil,
          normalized_value: float() | nil,
          student_normalized_value: float() | nil,
          scale_type: String.t(),
          is_missing: boolean(),
          use_manual_input: boolean(),
          calculation_error: String.t() | nil,
          has_marking: boolean(),
          has_evidences: boolean(),
          is_strand_entry: boolean(),
          assessment_point: AssessmentPoint.t(),
          assessment_point_id: pos_integer(),
          student: Student.t(),
          student_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          ordinal_value: OrdinalValue.t() | nil,
          ordinal_value_id: pos_integer() | nil,
          student_ordinal_value: OrdinalValue.t() | nil,
          student_ordinal_value_id: pos_integer() | nil,
          differentiation_rubric: Rubric.t() | nil,
          differentiation_rubric_id: pos_integer() | nil,
          assessment_point_entry_evidences: [AssessmentPointEntryEvidence.t()],
          evidences: [Attachment.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "assessment_point_entries" do
    field :observation, :string
    field :report_note, :string
    field :student_report_note, :string
    field :score, :float
    field :student_score, :float
    # precise pre-rounding weighted average stored when an ordinal entry is
    # computed via average composition. Lets downstream (grade-report)
    # compositions use the exact value instead of the ordinal value's
    # rounded representative normalized_value.
    field :normalized_value, :float
    field :student_normalized_value, :float
    field :scale_type, :string
    field :is_missing, :boolean, default: false
    field :use_manual_input, :boolean, default: false
    field :calculation_error, :string
    # has_marking is generated
    field :has_marking, :boolean, read_after_writes: true

    field :has_evidences, :boolean, virtual: true

    # we use this virtual field in the assessments grid context.
    # we have mixed moments and strands entries, but we just
    # want the strand entries to be editable
    field :is_strand_entry, :boolean, virtual: true

    belongs_to :assessment_point, AssessmentPoint
    belongs_to :student, Student
    belongs_to :scale, Scale
    belongs_to :ordinal_value, OrdinalValue
    belongs_to :student_ordinal_value, OrdinalValue
    belongs_to :differentiation_rubric, Rubric

    has_many :assessment_point_entry_evidences, AssessmentPointEntryEvidence
    has_many :evidences, through: [:assessment_point_entry_evidences, :attachment]

    timestamps()
  end

  @doc """
  Blank assessment point entry changeset.
  To be used during assessment point `changeset`.
  No `assessment_point_id` requirement (will be created during insert in `cast_assoc`).
  """
  def blank_changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [:assessment_point_id, :student_id, :scale_id, :scale_type])
    |> validate_required([:student_id, :scale_id, :scale_type])
  end

  @doc """
  A simple changeset without `validate_marking/1`.
  We use this to create assessment point entries forms,
  avoiding the nested queries required by the "full" changeset
  """
  def simple_changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [
      :observation,
      :score,
      :normalized_value,
      :student_normalized_value,
      :is_missing,
      :use_manual_input,
      :assessment_point_id,
      :student_id,
      :scale_id,
      :scale_type,
      :ordinal_value_id,
      :differentiation_rubric_id
    ])
    |> validate_required([:assessment_point_id, :student_id, :scale_id, :scale_type])
  end

  @doc false
  def changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [
      :observation,
      :report_note,
      :student_report_note,
      :score,
      :student_score,
      :normalized_value,
      :student_normalized_value,
      :is_missing,
      :use_manual_input,
      :calculation_error,
      :assessment_point_id,
      :student_id,
      :scale_id,
      :scale_type,
      :ordinal_value_id,
      :student_ordinal_value_id,
      :differentiation_rubric_id
    ])
    |> validate_required([:assessment_point_id, :student_id, :scale_id, :scale_type])
    |> validate_score_value()
    |> maybe_clear_is_missing()
    |> maybe_clear_normalized_value(:ordinal_value_id, :normalized_value)
    |> maybe_clear_normalized_value(:student_ordinal_value_id, :student_normalized_value)
  end

  defp maybe_clear_is_missing(changeset) do
    has_value =
      Enum.any?([:ordinal_value_id, :score], fn field ->
        get_field(changeset, field) not in [nil, ""]
      end)

    if has_value, do: put_change(changeset, :is_missing, false), else: changeset
  end

  # The stored normalized value is only valid alongside the ordinal value it was
  # computed for. When the ordinal value is changed by any path that doesn't also
  # supply the normalized value (e.g. manual teacher input), invalidate it. The
  # composition recalc always supplies both, so it keeps the precise value.
  defp maybe_clear_normalized_value(changeset, ordinal_field, normalized_field) do
    changing_ordinal? = Map.has_key?(changeset.changes, ordinal_field)
    keeping_normalized? = Map.has_key?(changeset.changes, normalized_field)

    if changing_ordinal? and not keeping_normalized? do
      put_change(changeset, normalized_field, nil)
    else
      changeset
    end
  end

  defp validate_score_value(%{valid?: true} = changeset) do
    case {get_field(changeset, :scale_type), get_change(changeset, :score)} do
      {"numeric", score} when is_float(score) ->
        scale =
          get_field(changeset, :scale_id)
          |> then(&Lanttern.Repo.get!(Scale, &1))

        changeset
        |> validate_number(:score,
          greater_than_or_equal_to: 0.0,
          less_than_or_equal_to: scale.max_score,
          message: "score should be between 0 and #{scale.max_score}"
        )

      _ ->
        changeset
    end
  end

  defp validate_score_value(changeset), do: changeset
end
