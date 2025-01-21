defmodule Lanttern.LearningContext.MomentCard do
  @moduledoc """
  The `MomentCard` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.LearningContext.Moment

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          description: String.t(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "moment_cards" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string

    belongs_to :moment, Moment

    timestamps()
  end

  @doc false
  def changeset(moment_card, attrs) do
    moment_card
    |> cast(attrs, [:name, :description, :position, :moment_id])
    |> validate_required([:name, :description, :position, :moment_id])
  end
end
