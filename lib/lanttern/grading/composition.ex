defmodule Lanttern.Grading.Composition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grade_compositions" do
    field :name, :string

    has_many :components, Lanttern.Grading.CompositionComponent
    belongs_to :final_grade_scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(composition, attrs) do
    composition
    |> cast(attrs, [:name, :final_grade_scale_id])
    |> validate_required([:name, :final_grade_scale_id])
  end
end
