defmodule Lanttern.LearningContext.Moment do
  @moduledoc """
  The `Moment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.LearningContext.Strand

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          description: String.t() | nil,
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          assessment_points: [AssessmentPoint.t()] | Ecto.Association.NotLoaded.t(),
          curriculum_items: [CurriculumItem.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "moments" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string

    belongs_to :strand, Strand

    has_many :assessment_points, AssessmentPoint, preload_order: [asc: :position]

    has_many :curriculum_items,
      through: [:assessment_points, :curriculum_item]

    timestamps()
  end

  @doc false
  def changeset(moment, attrs) do
    moment
    |> cast(attrs, [:name, :description, :position, :strand_id])
    |> validate_required([:name, :position, :strand_id])
  end

  def delete_changeset(moment) do
    moment
    |> cast(%{}, [])
    |> foreign_key_constraint(
      :id,
      name: :assessment_points_moment_id_fkey,
      message: gettext("Moment has linked assessment points.")
    )
  end
end
