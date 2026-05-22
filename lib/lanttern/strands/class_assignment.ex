defmodule Lanttern.Strands.ClassAssignment do
  @moduledoc """
  The `ClassAssignment` schema — links a strand to a class.
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Class

  @type t :: %__MODULE__{
          id: pos_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          class: Class.t() | Ecto.Association.NotLoaded.t(),
          class_id: pos_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "strand_class_assignments" do
    belongs_to :strand, Strand
    belongs_to :class, Class

    timestamps()
  end

  @doc false
  def changeset(class_assignment, attrs) do
    class_assignment
    |> cast(attrs, [:strand_id, :class_id])
    |> validate_required([:strand_id, :class_id])
    |> unique_constraint([:strand_id, :class_id],
      message: gettext("Class already assigned to this strand")
    )
  end
end
