defmodule Lanttern.ILP.ILPTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPSection
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          is_editing: boolean() | nil,
          school_id: pos_integer(),
          school: School.t(),
          sections: [ILPSection.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_templates" do
    field :name, :string
    field :description, :string
    field :is_editing, :boolean, virtual: true

    belongs_to :school, School

    has_many :sections, ILPSection,
      foreign_key: :template_id,
      preload_order: [asc: :position]

    timestamps()
  end

  @doc false
  def changeset(ilp_template, attrs) do
    ilp_template
    |> cast(attrs, [:name, :description, :school_id])
    |> cast_assoc(:sections)
    |> validate_required([:name, :school_id])
  end
end
