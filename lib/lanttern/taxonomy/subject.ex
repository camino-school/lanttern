defmodule Lanttern.Taxonomy.Subject do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: []
  }

  schema "subjects" do
    field :name, :string
    field :code, :string

    many_to_many :curriculum_items, Lanttern.Curricula.CurriculumItem,
      join_through: "curriculum_items_subjects"

    timestamps()
  end

  @doc false
  def changeset(subject, attrs) do
    subject
    |> cast(attrs, [:name, :code])
    |> validate_required([:name])
  end
end
