defmodule Lanttern.ILP.ILPTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          school_id: pos_integer(),
          school: School.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_templates" do
    field :name, :string
    field :description, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(ilp_template, attrs) do
    ilp_template
    |> cast(attrs, [:name, :description, :school_id])
    |> validate_required([:name, :school_id])
  end
end
