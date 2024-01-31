defmodule Lanttern.LearningContext.MomentCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "moment_cards" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string

    belongs_to :moment, Lanttern.LearningContext.Moment

    timestamps()
  end

  @doc false
  def changeset(moment_card, attrs) do
    moment_card
    |> cast(attrs, [:name, :description, :position, :moment_id])
    |> validate_required([:name, :description, :position, :moment_id])
  end
end
