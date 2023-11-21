defmodule Lanttern.LearningContext.Strand do
  use Ecto.Schema
  import Ecto.Changeset

  import Lanttern.SchemaHelpers

  schema "strands" do
    field :name, :string
    field :description, :string
    field :subjects_ids, {:array, :id}, virtual: true
    field :years_ids, {:array, :id}, virtual: true

    has_many :curriculum_items, Lanttern.LearningContext.StrandCurriculumItem,
      on_replace: :delete,
      preload_order: [asc: :position]

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
    |> cast(attrs, [:name, :description, :subjects_ids, :years_ids])
    |> validate_required([:name, :description])
    |> cast_assoc(:curriculum_items, with: &child_position_changeset/3)
    |> put_subjects()
    |> put_years()
  end
end
