defmodule Lanttern.LearningContext.Strand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "strands" do
    field :name, :string
    field :description, :string

    timestamps()
  end

  @doc false
  def changeset(strand, attrs) do
    strand
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
