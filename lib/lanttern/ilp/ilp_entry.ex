defmodule Lanttern.ILP.ILPEntry do
  @moduledoc """
  The `ILPEntry` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPComponent
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.StudentILP

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t() | nil,
          student_ilp_id: pos_integer(),
          student_ilp: StudentILP.t() | Ecto.Association.NotLoaded.t(),
          component_id: pos_integer(),
          component: ILPComponent.t() | Ecto.Association.NotLoaded.t(),
          template_id: pos_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_entries" do
    field :description, :string

    belongs_to :student_ilp, StudentILP
    belongs_to :component, ILPComponent
    belongs_to :template, ILPTemplate

    timestamps()
  end

  @doc false
  def changeset(ilp_entry, attrs) do
    ilp_entry
    |> cast(attrs, [:description, :student_ilp_id, :component_id, :template_id])
    # required component_id and student_ilp_id not included to allow cast_assoc
    |> validate_required([:template_id])
  end
end
