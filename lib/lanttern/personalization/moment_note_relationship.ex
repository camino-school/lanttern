defmodule Lanttern.Personalization.MomentNoteRelationship do
  @moduledoc """
  The `MomentNoteRelationship` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import LantternWeb.Gettext

  @primary_key false
  schema "moments_notes" do
    belongs_to :note, Lanttern.Personalization.Note
    belongs_to :author, Lanttern.Identity.Profile
    belongs_to :moment, Lanttern.LearningContext.Moment
  end

  @doc false
  def changeset(moment_note_relationship, attrs) do
    moment_note_relationship
    |> cast(attrs, [:note_id, :author_id, :moment_id])
    |> validate_required([:note_id, :author_id, :moment_id])
    |> unique_constraint(
      :note_id,
      name: "moments_notes_author_id_moment_id_index",
      message: gettext("Author already has a note for this moment")
    )
  end
end
