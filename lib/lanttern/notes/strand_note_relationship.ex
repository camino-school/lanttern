defmodule Lanttern.Notes.StrandNoteRelationship do
  @moduledoc """
  The `StrandNoteRelationship` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Notes.Note

  @type t :: %__MODULE__{
          note: Note.t(),
          note_id: pos_integer(),
          author: Profile.t(),
          author_id: pos_integer(),
          strand: Strand.t(),
          strand_id: pos_integer()
        }

  @primary_key false
  schema "strands_notes" do
    belongs_to :note, Note
    belongs_to :author, Profile
    belongs_to :strand, Strand
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
