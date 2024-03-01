defmodule Lanttern.Taxonomy.Year do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          code: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
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
