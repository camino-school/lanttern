defmodule Lanttern.Curricula.CurriculumItem do
  @moduledoc """
  The `CurriculumItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import Lanttern.SchemaHelpers

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          code: String.t() | nil,
          subjects_ids: [pos_integer()],
          years_ids: [pos_integer()],
          assessment_point_id: pos_integer() | nil,
          is_differentiation: boolean(),
          has_rubric: boolean(),
          assessment_points: [AssessmentPoint.t()] | Ecto.Association.NotLoaded.t(),
          curriculum_component: CurriculumComponent.t() | Ecto.Association.NotLoaded.t(),
          curriculum_component_id: pos_integer(),
          subjects: [Subject.t()] | Ecto.Association.NotLoaded.t(),
          years: [Year.t()] | Ecto.Association.NotLoaded.t(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer() | nil,
          children_id: pos_integer() | nil,
          component_code: String.t() | nil,
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

    # we use this when listing curriculum items as goals
    # reflecting the parent assessment_point rubric_id
    field :has_rubric, :boolean, virtual: true, default: false

    has_many :assessment_points, AssessmentPoint
    belongs_to :curriculum_component, CurriculumComponent
    belongs_to :school, School

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
  def changeset(curriculum_item, attrs, %Scope{} = scope) do
    curriculum_item
    |> cast(attrs, [:name, :code, :curriculum_component_id, :subjects_ids, :years_ids])
    |> put_change(:school_id, scope.school_id)
    |> validate_required([:name, :curriculum_component_id, :school_id])
    |> put_subjects()
    |> put_years()
  end
end
