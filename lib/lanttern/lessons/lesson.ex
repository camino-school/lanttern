defmodule Lanttern.Lessons.Lesson do
  @moduledoc """
  The `Lesson` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          position: non_neg_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "lessons" do
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0

    belongs_to :strand, Strand
    belongs_to :moment, Moment

    timestamps()
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:name, :description, :position, :strand_id, :moment_id])
    |> validate_required([:name, :position, :strand_id])
  end
end
