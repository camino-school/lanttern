defmodule Lanttern.LearningContext.Moment do
  @moduledoc """
  The `Moment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext
  import Lanttern.SchemaHelpers

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Taxonomy.Subject

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          description: String.t(),
          subjects_ids: [pos_integer()],
          strand: Strand.t(),
          strand_id: pos_integer(),
          assessment_points: [AssessmentPoint.t()],
          curriculum_items: [CurriculumItem.t()],
          subjects: [Subject.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "moments" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string
    field :subjects_ids, {:array, :id}, virtual: true

    belongs_to :strand, Strand

    has_many :assessment_points, AssessmentPoint, preload_order: [asc: :position]

    has_many :curriculum_items,
      through: [:assessment_points, :curriculum_item]

    many_to_many :subjects, Subject,
      join_through: "moments_subjects",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(moment, attrs) do
    moment
    |> cast(attrs, [:name, :description, :position, :strand_id, :subjects_ids])
    |> validate_required([:name, :description, :position, :strand_id])
    |> put_subjects()
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
