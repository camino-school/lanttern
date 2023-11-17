defmodule Lanttern.LearningContext.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  import Lanttern.SchemaHelpers

  schema "activities" do
    field :name, :string
    field :position, :integer
    field :description, :string

    has_many :curriculum_items, Lanttern.LearningContext.ActivityCurriculumItem,
      on_replace: :delete,
      preload_order: [asc: :position]

    belongs_to :strand, Lanttern.LearningContext.Strand

    timestamps()
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:name, :description, :position, :strand_id])
    |> validate_required([:name, :description, :position, :strand_id])
    |> cast_assoc(:curriculum_items, with: &child_position_changeset/3)
  end
end
