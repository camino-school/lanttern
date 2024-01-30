defmodule Lanttern.LearningContext.Moment do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext
  import Lanttern.SchemaHelpers

  schema "moments" do
    field :name, :string
    field :position, :integer
    field :description, :string
    field :subjects_ids, {:array, :id}, virtual: true

    belongs_to :strand, Lanttern.LearningContext.Strand

    has_many :assessment_points, Lanttern.Assessments.AssessmentPoint

    has_many :curriculum_items,
      through: [:assessment_points, :curriculum_item]

    many_to_many :subjects, Lanttern.Taxonomy.Subject,
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
