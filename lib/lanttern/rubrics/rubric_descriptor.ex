defmodule Lanttern.Rubrics.RubricDescriptor do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Grading.Scale
  alias Lanttern.Grading.OrdinalValue

  @type t :: %__MODULE__{
          id: pos_integer(),
          descriptor: String.t(),
          scale_type: String.t(),
          score: float(),
          rubric: Rubric.t(),
          rubric_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          ordinal_value: OrdinalValue.t(),
          ordinal_value_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "rubric_descriptors" do
    field :descriptor, :string
    field :scale_type, :string
    field :score, :float

    belongs_to :rubric, Rubric
    belongs_to :scale, Scale
    belongs_to :ordinal_value, OrdinalValue

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
