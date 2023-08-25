defmodule Lanttern.Curricula.CurriculumComponent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "curriculum_components" do
    field :code, :string
    field :name, :string

    belongs_to :curriculum, Lanttern.Curricula.Curriculum

    timestamps()
  end

  @doc false
  def changeset(curriculum_component, attrs) do
    curriculum_component
    |> cast(attrs, [:name, :code, :curriculum_id])
    |> validate_required([:name, :curriculum_id])
  end
end
