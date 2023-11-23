defmodule Lanttern.Personalization.ActivityNoteRelationship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "activities_notes" do
    belongs_to :note, Lanttern.Personalization.Note
    belongs_to :author, Lanttern.Identity.Profile
    belongs_to :activity, Lanttern.LearningContext.Activity
  end

  @doc false
  def changeset(activity_note_relationship, attrs) do
    activity_note_relationship
    |> cast(attrs, [:note_id, :author_id, :activity_id])
    |> validate_required([:note_id, :author_id, :activity_id])
    |> unique_constraint(
      :note_id,
      name: "activities_notes_author_id_activity_id_index",
      message: "Author already has a note for this activity"
    )
  end
end
