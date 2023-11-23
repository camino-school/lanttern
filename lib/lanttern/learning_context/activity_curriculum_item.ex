defmodule Lanttern.LearningContext.ActivityCurriculumItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities_curriculum_items" do
    field :position, :integer

    belongs_to :activity, Lanttern.LearningContext.Activity
    belongs_to :curriculum_item, Lanttern.Curricula.CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(activity_curriculum_item, attrs) do
    activity_curriculum_item
    |> cast(attrs, [:position, :activity_id, :curriculum_item_id])
    |> validate_required([:position, :activity_id, :curriculum_item_id])
  end
end
