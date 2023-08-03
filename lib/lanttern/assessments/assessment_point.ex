defmodule Lanttern.Assessments.AssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_points" do
    field :name, :string
    field :date, :utc_datetime
    field :description, :string

    belongs_to :curriculum_item, Lanttern.Curricula.Item
    belongs_to :scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [:name, :date, :description, :curriculum_item_id, :scale_id])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
  end
end
