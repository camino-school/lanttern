defmodule Lanttern.Rubrics.Rubric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rubrics" do
    field :criteria, :string
    field :is_differentiation, :boolean, default: false

    belongs_to :scale, Lanttern.Grading.Scale
    has_many :descriptors, Lanttern.Rubrics.RubricDescriptor, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [:criteria, :is_differentiation, :scale_id])
    |> validate_required([:criteria, :is_differentiation, :scale_id])
    |> cast_assoc(:descriptors)
  end
end
