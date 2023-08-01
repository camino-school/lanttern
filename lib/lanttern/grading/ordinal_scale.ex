defmodule Lanttern.Grading.OrdinalScale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ordinal_scales" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(ordinal_scale, attrs) do
    ordinal_scale
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
