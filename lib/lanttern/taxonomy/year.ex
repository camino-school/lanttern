defmodule Lanttern.Taxonomy.Year do
  use Ecto.Schema
  import Ecto.Changeset

  schema "years" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(year, attrs) do
    year
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
