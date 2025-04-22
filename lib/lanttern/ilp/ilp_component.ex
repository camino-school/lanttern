defmodule Lanttern.ILP.ILPComponent do
  @moduledoc """
  The `ILPComponent` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPEntry
  alias Lanttern.ILP.ILPSection
  alias Lanttern.ILP.ILPTemplate

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          template_id: pos_integer(),
          section_id: pos_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          section: ILPSection.t() | Ecto.Association.NotLoaded.t(),
          entry: ILPEntry.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_components" do
    field :name, :string
    field :position, :integer, default: 0

    belongs_to :template, ILPTemplate
    belongs_to :section, ILPSection

    # actually, it's a has_many relationship in the db,
    # but we'll deal with a single entry per component
    has_one :entry, ILPEntry, foreign_key: :component_id

    timestamps()
  end

  @doc false
  def changeset(ilp_component, attrs, position \\ 0) do
    ilp_component
    |> cast(attrs, [:name, :position, :template_id, :section_id])
    |> maybe_change_position(position)
    |> cast_assoc(:entry)
    |> validate_required([:name, :position])
  end

  defp maybe_change_position(changeset, position) do
    case get_change(changeset, :position) do
      nil -> change(changeset, position: position)
      _ -> changeset
    end
  end
end
