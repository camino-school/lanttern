defmodule Lanttern.LearningContext.Strand do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext
  import Lanttern.SchemaHelpers

  schema "strands" do
    field :name, :string
    field :type, :string
    field :description, :string
    field :cover_image_url, :string
    field :subject_id, :id, virtual: true
    field :subjects_ids, {:array, :id}, virtual: true
    field :year_id, :id, virtual: true
    field :years_ids, {:array, :id}, virtual: true
    field :is_starred, :boolean, virtual: true

    has_many :moments, Lanttern.LearningContext.Moment
    has_many :assessment_points, Lanttern.Assessments.AssessmentPoint

    many_to_many :subjects, Lanttern.Taxonomy.Subject,
      join_through: "strands_subjects",
      on_replace: :delete

    many_to_many :years, Lanttern.Taxonomy.Year,
      join_through: "strands_years",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(strand, attrs) do
    strand
    |> cast(attrs, [:name, :type, :description, :cover_image_url, :subjects_ids, :years_ids])
    |> validate_required([:name, :description])
    |> put_subjects()
    |> put_years()
  end

  def delete_changeset(strand) do
    strand
    |> cast(%{}, [])
    |> foreign_key_constraint(
      :id,
      name: :moments_strand_id_fkey,
      message: gettext("Strand has linked moments.")
    )
    |> foreign_key_constraint(
      :id,
      name: :assessment_points_strand_id_fkey,
      message: gettext("Strand has linked assessment points.")
    )
  end
end
