defmodule Lanttern.ILP.ILPSection do
  @moduledoc """
  The `ILPSection` schema
  """

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
      on_replace: :delete,
      preload_order: [asc: :position]

    timestamps()
  end

  @doc false
  def changeset(ilp_section, attrs, position \\ 0) do
    ilp_section
    |> cast(attrs, [:name, :position, :template_id])
    |> maybe_change_position(position)
    |> cast_assoc(:components,
      sort_param: :components_sort,
      drop_param: :components_drop,
      with: &ILPComponent.changeset/3
    )
    |> validate_required([:name, :position])
  end

  defp maybe_change_position(changeset, position) do
    case get_change(changeset, :position) do
      nil -> change(changeset, position: position)
      _ -> changeset
    end
  end
end
