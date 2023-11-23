defmodule Lanttern.Personalization.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :description, :string

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
