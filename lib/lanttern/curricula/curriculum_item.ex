defmodule Lanttern.Curricula.CurriculumItem do
  use Ecto.Schema
  import Ecto.Changeset

  import Lanttern.SchemaHelpers

  @derive {
    Flop.Schema,
    filterable: [:subjects_ids, :years_ids, :subject_id, :year_id],
    sortable: [:code],
    adapter_opts: [
      join_fields: [
        subjects_ids: [
          binding: :subjects,
          field: :id,
          ecto_type: :id
        ],
        years_ids: [
          binding: :years,
          field: :id,
          ecto_type: :id
        ],
        subject_id: [
          binding: :subjects,
          field: :id,
          ecto_type: :id
        ],
        year_id: [
          binding: :years,
          field: :id,
          ecto_type: :id
        ]
      ]
    ]
  }

  schema "curriculum_items" do
    field :name, :string
    field :code, :string
    field :subjects_ids, {:array, :id}, virtual: true
    field :years_ids, {:array, :id}, virtual: true
    field :assessment_point_id, :id, virtual: true

    # we use this when listing curriculum items as goals
    # reflecting the parent assessment_point is_differentiation flag
    field :is_differentiation, :boolean, virtual: true, default: false

    has_many :grade_composition_component_items, Lanttern.Grading.CompositionComponentItem
    has_many :assessment_points, Lanttern.Assessments.AssessmentPoint
    belongs_to :curriculum_component, Lanttern.Curricula.CurriculumComponent

    many_to_many :subjects, Lanttern.Taxonomy.Subject,
      join_through: "curriculum_items_subjects",
      on_replace: :delete

    many_to_many :years, Lanttern.Taxonomy.Year,
      join_through: "curriculum_items_years",
      on_replace: :delete

    timestamps()

    # query "helper" virtual fields
    field :children_id, :id, virtual: true
    field :component_code, :string, virtual: true
  end

  @doc false
  def changeset(curriculum_item, attrs) do
    curriculum_item
    |> cast(attrs, [:name, :code, :curriculum_component_id, :subjects_ids, :years_ids])
    |> validate_required([:name, :curriculum_component_id])
    |> put_subjects()
    |> put_years()
  end
end
