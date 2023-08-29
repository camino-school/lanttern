defmodule Lanttern.Taxonomy.Year do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: []
  }

  schema "years" do
    field :name, :string
    field :code, :string

    timestamps()
  end

  @doc false
  def changeset(year, attrs) do
    year
    |> cast(attrs, [:name, :code])
    |> validate_required([:name])
  end
end
