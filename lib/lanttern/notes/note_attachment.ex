defmodule Lanttern.Notes.NoteAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.Identity.Profile
  alias Lanttern.Notes.Note

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          owner: Profile.t(),
          owner_id: pos_integer(),
          note: Note.t(),
          note_id: pos_integer(),
          attachment: Attachment.t(),
          attachment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "notes_attachments" do
    field :position, :integer, default: 0

    belongs_to :owner, Profile
    belongs_to :note, Note
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(note_attachment, attrs) do
    note_attachment
    |> cast(attrs, [:position, :owner_id, :note_id, :attachment_id])
    |> validate_required([:owner_id, :note_id, :attachment_id])
  end
end
