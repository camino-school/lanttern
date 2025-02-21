defmodule Lanttern.ILP.ILPTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  schema "ilp_templates" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(ilp_template, attrs) do
    ilp_template
    |> cast(attrs, [:name, :position, :description, :school_id])
    |> validate_required([:name, :position, :school_id])
  end
end
