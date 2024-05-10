defmodule Lanttern.NotesLog.NoteLog do
  @moduledoc """
  The `NoteLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "notes" do
    field :note_id, :integer
    field :author_id, :integer
    field :description, :string
    field :operation, :string
    field :type, :string
    field :type_id, :integer

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(note_log, attrs) do
    note_log
    |> cast(attrs, [:note_id, :author_id, :description, :operation, :type, :type_id])
    |> validate_required([:note_id, :author_id, :description, :operation])
  end
end
