defmodule Lanttern.Assessments.AssessmentPointEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_point_entries" do
    field :observation, :string
    field :score, :float

    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :ordinal_value, Lanttern.Grading.OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [:observation, :score, :assessment_point_id, :student_id, :ordinal_value_id])
    |> validate_required([:assessment_point_id, :student_id])
    |> validate_marking()
  end

  # what are we are calling marking here?
  # score for numeric scales or ordinal values for ordinal scales
  # skip if valid? = false because we need the assessment_point_id (checked above) for this validation
  defp validate_marking(%{valid?: true} = changeset) do
    assessment_point_id = get_field(changeset, :assessment_point_id)
    %{scale: scale} = Lanttern.Assessments.get_assessment_point!(assessment_point_id, :scale)

    case scale.type do
      "numeric" ->
        changeset
        |> validate_number(:score,
          greater_than_or_equal_to: scale.start,
          less_than_or_equal_to: scale.stop,
          message: "score should be between #{scale.start} and #{scale.stop}"
        )

      "ordinal" ->
        allowed_ordinal_value_ids =
          Lanttern.Grading.list_ordinal_values_from_scale(scale.id)
          |> Enum.map(& &1.id)

        changeset
        |> validate_inclusion(
          :ordinal_value_id,
          allowed_ordinal_value_ids,
          message: "Select an ordinal value from #{scale.name} scale"
        )

      _ ->
        changeset
    end
  end

  defp validate_marking(changeset), do: changeset
end
