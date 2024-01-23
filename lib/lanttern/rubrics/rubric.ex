defmodule Lanttern.Rubrics.Rubric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rubrics" do
    field :criteria, :string
    field :is_differentiation, :boolean, default: false

    belongs_to :scale, Lanttern.Grading.Scale
    belongs_to :parent_rubric, __MODULE__, foreign_key: :diff_for_rubric_id

    has_many :descriptors, Lanttern.Rubrics.RubricDescriptor, on_replace: :delete
    has_many :differentiation_rubrics, __MODULE__, foreign_key: :diff_for_rubric_id
    has_many :assessment_points, Lanttern.Assessments.AssessmentPoint

    many_to_many :students, Lanttern.Schools.Student,
      join_through: "differentiation_rubrics_students"

    timestamps()
  end

  @doc false
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [:criteria, :is_differentiation, :diff_for_rubric_id, :scale_id])
    |> validate_required([:criteria, :is_differentiation, :scale_id])
    |> cast_assoc(:descriptors)
    |> foreign_key_constraint(
      :diff_for_rubric_id,
      name: :rubrics_diff_for_rubric_id_fkey,
      message:
        "This rubric has linked differentiation rubrics. Deleting it is not allowed, as it would cause data loss."
    )
  end
end
