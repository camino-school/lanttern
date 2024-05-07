defmodule Lanttern.Personalization.Note do
  @moduledoc """
  The `Note` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.LearningContext.Strand
  alias Lanttern.LearningContext.Moment

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

    # notes can be linked to other schemas through intermediate join tables/schemas.
    # we use the "virtual" belongs_to below to preload those schemas in notes
    belongs_to :strand, Strand, define_field: false
    belongs_to :moment, Moment, define_field: false

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:description, :author_id])
    |> validate_required([:description, :author_id])
  end
end
