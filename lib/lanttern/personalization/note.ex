defmodule Lanttern.Personalization.Note do
  @moduledoc """
  The `Note` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.LearningContext.Strand
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Personalization.MomentNoteRelationship
  alias Lanttern.Personalization.StrandNoteRelationship

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          author: Profile.t(),
          author_id: pos_integer(),
          strand: Strand.t(),
          moment: Moment.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "notes" do
    field :description, :string

    belongs_to :author, Profile
    has_one :strand_note_relationship, StrandNoteRelationship
    has_one :strand, through: [:strand_note_relationship, :strand]
    has_one :moment_note_relationship, MomentNoteRelationship
    has_one :moment, through: [:moment_note_relationship, :moment]

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:description, :author_id])
    |> validate_required([:description, :author_id])
  end
end
