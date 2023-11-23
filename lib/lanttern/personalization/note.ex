defmodule Lanttern.Personalization.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :description, :string

    # notes can be linked to strands/activities
    # we use this virtual field to "preload" strand or activity in notes
    field :strand, :map, virtual: true
    field :activity, :map, virtual: true

    belongs_to :author, Lanttern.Identity.Profile

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:description, :author_id])
    |> validate_required([:description, :author_id])
  end
end
