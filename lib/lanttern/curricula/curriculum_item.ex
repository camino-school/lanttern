defmodule Lanttern.Curricula.CurriculumItem do
  @moduledoc """
  The `CurriculumItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import Lanttern.SchemaHelpers

  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          code: String.t(),
          subjects_ids: [pos_integer()],
          years_ids: [pos_integer()],
          assessment_point_id: pos_integer(),
          is_differentiation: boolean(),
          assessment_points: [map()],
          curriculum_component: map(),
          curriculum_component_id: pos_integer(),
          subjects: [Subject.t()],
          years: [Year.t()],
          children_id: pos_integer(),
          component_code: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
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

    has_many :assessment_points, Lanttern.Assessments.AssessmentPoint
    belongs_to :curriculum_component, Lanttern.Curricula.CurriculumComponent

    many_to_many :subjects, Subject,
      join_through: "curriculum_items_subjects",
      on_replace: :delete

    many_to_many :years, Year,
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
