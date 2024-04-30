defmodule Lanttern.Personalization.Note do
  @moduledoc """
  The `Note` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :description, :string

    belongs_to :author, Lanttern.Identity.Profile

    # notes can be linked to other schemas through intermediate join tables/schemas.
    # we use the "virtual" belongs_to below to preload those schemas in notes
    belongs_to :strand, Lanttern.LearningContext.Strand, define_field: false
    belongs_to :moment, Lanttern.LearningContext.Moment, define_field: false

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:description, :author_id])
    |> validate_required([:description, :author_id])
  end
end
