defmodule Lanttern.Conversation.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :comment, :string

    belongs_to :profile, Lanttern.Identity.Profile

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:comment, :profile_id])
    |> validate_required([:comment, :profile_id])
    |> foreign_key_constraint(:profile_id, message: "Profile not found")
  end
end
