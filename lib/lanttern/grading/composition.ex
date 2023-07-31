defmodule Lanttern.Grading.Composition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grade_compositions" do
    field :name, :string

    has_many :components, Lanttern.Grading.CompositionComponent

    timestamps()
  end

  @doc false
  def changeset(composition, attrs) do
    composition
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
