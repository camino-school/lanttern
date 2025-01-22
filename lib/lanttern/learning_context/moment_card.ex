defmodule Lanttern.LearningContext.MomentCard do
  @moduledoc """
  The `MomentCard` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.MomentCardAttachment

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          description: String.t(),
          attachments_count: non_neg_integer(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer(),
          moment_card_attachments: [MomentCardAttachment.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "moment_cards" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string

    field :attachments_count, :integer, virtual: true, default: 0

    belongs_to :moment, Moment

    has_many :moment_card_attachments, MomentCardAttachment

    timestamps()
  end

  @doc false
  def changeset(moment_card, attrs) do
    moment_card
    |> cast(attrs, [:name, :description, :position, :moment_id])
    |> validate_required([:name, :description, :position, :moment_id])
  end
end
