defmodule Lanttern.Rubrics.RubricDescriptor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rubric_descriptors" do
    field :descriptor, :string
    field :scale_type, :string
    field :score, :float

    belongs_to :rubric, Lanttern.Rubrics.Rubric
    belongs_to :scale, Lanttern.Grading.Scale
    belongs_to :ordinal_value, Lanttern.Grading.OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(rubric_descriptor, attrs) do
    rubric_descriptor
    |> cast(attrs, [:descriptor, :scale_type, :score, :rubric_id, :scale_id, :ordinal_value_id])
    |> validate_required([:descriptor, :scale_type, :scale_id])
    |> foreign_key_constraint(
      :rubric_id,
      name: :rubric_descriptors_rubric_id_fkey,
      message:
        "Error referencing rubric. Check if it exists and references the same scale being referenced here."
    )
    |> foreign_key_constraint(
      :rubric_id,
      name: :rubric_descriptors_scale_type_fkey,
      message: "The scale type should be the same of the scale being referenced here."
    )
    |> foreign_key_constraint(
      :rubric_id,
      name: :rubric_descriptors_ordinal_value_id_fkey,
      message:
        "Error referencing ordinal value. Check if it exists and references the same scale being referenced here."
    )
    |> check_constraint(
      :ordinal_value_id,
      name: :required_scale_type_related_value,
      message: "Ordinal value is required for ordinal scale descriptors."
    )
    |> check_constraint(
      :score,
      name: :required_scale_type_related_value,
      message: "Score is required for numeric scale descriptors."
    )
    |> unique_constraint(
      :score,
      name: :rubric_descriptors_score_rubric_id_index,
      message: "Two distinct descriptors for the same score is not allowed."
    )
  end
end
