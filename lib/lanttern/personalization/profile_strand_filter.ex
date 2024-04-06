defmodule Lanttern.Personalization.ProfileStrandFilter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Class

  @type t :: %__MODULE__{
          id: pos_integer(),
          profile: Profile.t(),
          profile_id: pos_integer(),
          strand: Strand.t(),
          strand_id: pos_integer(),
          class: Class.t(),
          class_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "profile_strand_filters" do
    belongs_to :profile, Profile
    belongs_to :strand, Strand
    belongs_to :class, Class

    timestamps()
  end

  @doc false
  def changeset(profile_strand_filter, attrs) do
    profile_strand_filter
    |> cast(attrs, [:profile_id, :strand_id, :class_id])
    |> validate_required([:profile_id, :strand_id, :class_id])
  end
end
