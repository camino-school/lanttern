defmodule Lanttern.Curricula.CurriculumComponent do
  @moduledoc """
  The `CurriculumComponent` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          code: String.t() | nil,
          name: String.t(),
          description: String.t() | nil,
          position: non_neg_integer(),
          bg_color: String.t() | nil,
          text_color: String.t() | nil,
          curriculum: Curriculum.t() | Ecto.Association.NotLoaded.t(),
          curriculum_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "curriculum_components" do
    field :code, :string
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0
    field :bg_color, :string
    field :text_color, :string

    belongs_to :curriculum, Curriculum
    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(curriculum_component, attrs, %Scope{} = scope) do
    curriculum_component
    |> cast(attrs, [:code, :name, :description, :position, :bg_color, :text_color, :curriculum_id])
    |> put_change(:school_id, scope.school_id)
    |> validate_required([:name, :curriculum_id, :school_id])
    |> validate_hex_color(:bg_color, :bg_color_should_be_hex)
    |> validate_hex_color(:text_color, :text_color_should_be_hex)
  end
end
