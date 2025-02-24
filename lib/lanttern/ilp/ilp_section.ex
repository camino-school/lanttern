defmodule Lanttern.ILP.ILPSection do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.ILPComponent

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          template_id: pos_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          components: [ILPComponent.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_sections" do
    field :name, :string
    field :position, :integer

    belongs_to :template, ILPTemplate

    has_many :components, ILPComponent,
      foreign_key: :section_id,
      preload_order: [asc: :position]

    timestamps()
  end

  @doc false
  def changeset(ilp_section, attrs) do
    ilp_section
    |> cast(attrs, [:name, :position, :template_id])
    |> cast_assoc(:components)
    |> validate_required([:name, :position])
  end
end
