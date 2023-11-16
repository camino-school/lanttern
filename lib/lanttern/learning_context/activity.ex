defmodule Lanttern.LearningContext.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field :name, :string
    field :position, :integer
    field :description, :string

    belongs_to :strand, Lanttern.LearningContext.Strand

    timestamps()
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:name, :description, :position, :strand_id])
    |> validate_required([:name, :description, :position, :strand_id])
  end
end
