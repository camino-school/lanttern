defmodule Lanttern.ILP.ILPComponent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.ILPSection

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          template_id: pos_integer(),
          section_id: pos_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          section: ILPSection.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_components" do
    field :name, :string
    field :position, :integer, default: 0

    belongs_to :template, ILPTemplate
    belongs_to :section, ILPSection

    timestamps()
  end

  @doc false
  def changeset(ilp_component, attrs) do
    ilp_component
    |> cast(attrs, [:name, :position, :template_id, :section_id])
    |> validate_required([:name, :position, :template_id, :section_id])
  end
end
