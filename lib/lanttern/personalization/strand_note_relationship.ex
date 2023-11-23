defmodule Lanttern.Personalization.StrandNoteRelationship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "strands_notes" do
    belongs_to :note, Lanttern.Personalization.Note
    belongs_to :author, Lanttern.Identity.Profile
    belongs_to :strand, Lanttern.LearningContext.Strand
  end

  @doc false
  def changeset(strand_note_relationship, attrs) do
    strand_note_relationship
    |> cast(attrs, [:note_id, :author_id, :strand_id])
    |> validate_required([:note_id, :author_id, :strand_id])
    |> unique_constraint(
      :note_id,
      name: "strands_notes_author_id_strand_id_index",
      message: "Author already has a note for this strand"
    )
  end
end
