defmodule Lanttern.SchoolConfig.MomentCardTemplate do
  @moduledoc """
  The `MomentCardTemplate` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          template: String.t(),
          instructions: String.t() | nil,
          position: non_neg_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "moment_cards_templates" do
    field :name, :string
    field :template, :string
    field :instructions, :string
    field :position, :integer, default: 0

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(moment_card_template, attrs, scope) do
    moment_card_template
    |> cast(attrs, [:name, :template, :instructions, :position])
    |> validate_required([:name, :template, :position])
    |> put_change(:school_id, scope.school_id)
  end
end
