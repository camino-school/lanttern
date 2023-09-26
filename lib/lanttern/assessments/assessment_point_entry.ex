defmodule Lanttern.Assessments.AssessmentPointEntry do
  @moduledoc """
  ### 🔺 don't use `Repo.preload/3` with `has_one :feedback` association

  There's actually no way Ecto can identify the exactly feedback
  that is associated to one entry only through schema — thus **using
  `Repo.preload/3` is not possible**.

  That's because the rule to this association is not based on
  `AssessmentPointEntry` or `Feedback` ids, but in the fact that
  both schemas share the same `assessment_point_id` and `student_id`.

  If we just use `Repo.preload/3`, Ecto will get all feedbacks related
  to the assessment point (using the `has_many :feedbacks` in `AssessmentPoint`)
  and return the first in the list — which is not what we want.

  BUT, having this `has_one` association is usefull because it allows
  us to use `Ecto.Query.preload/3` given that we build the correct query
  for this association.

  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_point_entries" do
    field :observation, :string
    field :score, :float

    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :ordinal_value, Lanttern.Grading.OrdinalValue

    # warning: don't use `Repo.preload/3` with this association.
    # we can get this in query, usign assessment_point_id and student_id
    # see moduledoc for more information
    has_one :feedback, through: [:assessment_point, :feedback]

    timestamps()
  end

  @doc """
  Blank assessment point entry changeset.
  To be used during assessment point `creation_changeset`.
  No `assessment_point_id` requirement (will be created during insert in `cast_assoc`).
  """
  def blank_changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [:assessment_point_id, :student_id])
    |> validate_required([:student_id])
  end

  @doc """
  A simple changeset without `validate_marking/1`.
  We use this to create assessment point entries forms,
  avoiding the nested queries required by the "full" changeset
  """
  def simple_changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [:observation, :score, :assessment_point_id, :student_id, :ordinal_value_id])
    |> validate_required([:assessment_point_id, :student_id])
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
    # we'll need scale for both numeric and ordinal validations
    # we are querying the data here to avoid unnecessary queries
    assessment_point_id = get_field(changeset, :assessment_point_id)
    %{scale: scale} = Lanttern.Assessments.get_assessment_point!(assessment_point_id, :scale)

    changeset
    |> validate_score_value(scale)
    |> validate_ordinal_value(scale)
  end

  defp validate_marking(changeset), do: changeset

  defp validate_score_value(changeset, %{type: "numeric"} = scale) do
    changeset
    |> validate_number(:score,
      greater_than_or_equal_to: scale.start,
      less_than_or_equal_to: scale.stop,
      message: "score should be between #{scale.start} and #{scale.stop}"
    )
  end

  defp validate_score_value(changeset, _scale), do: changeset

  defp validate_ordinal_value(changeset, %{type: "ordinal"} = scale) do
    allowed_ordinal_value_ids =
      Lanttern.Grading.list_ordinal_values_from_scale(scale.id)
      |> Enum.map(& &1.id)

    changeset
    |> validate_inclusion(
      :ordinal_value_id,
      allowed_ordinal_value_ids,
      message: "Select an ordinal value from #{scale.name} scale"
    )
  end

  defp validate_ordinal_value(changeset, _scale), do: changeset
end
