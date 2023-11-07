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
    field :scale_type, :string

    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :scale, Lanttern.Grading.Scale
    belongs_to :ordinal_value, Lanttern.Grading.OrdinalValue
    belongs_to :differentiation_rubric, Lanttern.Rubrics.Rubric

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
      :score,
      :assessment_point_id,
      :student_id,
      :scale_id,
      :scale_type,
      :ordinal_value_id,
      :differentiation_rubric_id
    ])
    |> validate_required([:assessment_point_id, :student_id, :scale_id, :scale_type])
    |> validate_score_value()
  end

  defp validate_score_value(%{valid?: true} = changeset) do
    case {get_field(changeset, :scale_type), get_change(changeset, :score)} do
      {"numeric", score} when is_float(score) ->
        scale =
          get_field(changeset, :scale_id)
          |> Lanttern.Grading.get_scale!()

        changeset
        |> validate_number(:score,
          greater_than_or_equal_to: scale.start,
          less_than_or_equal_to: scale.stop,
          message: "score should be between #{scale.start} and #{scale.stop}"
        )

      _ ->
        changeset
    end
  end

  defp validate_score_value(changeset), do: changeset
end
