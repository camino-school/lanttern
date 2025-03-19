defmodule Lanttern.ILP.ILPTemplate do
  @moduledoc """
  The `ILPTemplate` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPSection
  alias Lanttern.ILP.ILPTemplateAILayer
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          teacher_description: String.t() | nil,
          is_editing: boolean() | nil,
          school_id: pos_integer(),
          school: School.t(),
          sections: [ILPSection.t()] | Ecto.Association.NotLoaded.t(),
          ai_layer: ILPTemplateAILayer.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_templates" do
    field :name, :string
    field :description, :string
    field :teacher_description, :string
    field :is_editing, :boolean, virtual: true

    belongs_to :school, School

    has_many :sections, ILPSection,
      foreign_key: :template_id,
      on_replace: :delete,
      preload_order: [asc: :position]

    has_one :ai_layer, ILPTemplateAILayer,
      foreign_key: :template_id,
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(ilp_template, attrs) do
    ilp_template
    |> cast(attrs, [:name, :description, :teacher_description, :school_id])
    |> cast_assoc(:sections,
      sort_param: :sections_sort,
      drop_param: :sections_drop,
      with: &ILPSection.changeset/3
    )
    |> cast_assoc(:ai_layer)
    |> validate_required([:name, :school_id])
  end
end
