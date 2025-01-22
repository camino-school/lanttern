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
          teacher_instructions: String.t() | nil,
          differentiation: String.t() | nil,
          shared_with_students: boolean(),
          attachments_count: non_neg_integer(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer(),
          moment_card_attachments: [MomentCardAttachment.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "moment_cards" do
    field :name, :string
    field :position, :integer, default: 0
    field :description, :string
    field :teacher_instructions, :string
    field :differentiation, :string
    field :shared_with_students, :boolean, default: false

    field :attachments_count, :integer, virtual: true, default: 0

    belongs_to :moment, Moment

    has_many :moment_card_attachments, MomentCardAttachment

    timestamps()
  end

  @doc false
  def changeset(moment_card, attrs) do
    moment_card
    |> cast(attrs, [
      :name,
      :position,
      :description,
      :teacher_instructions,
      :differentiation,
      :shared_with_students,
      :moment_id
    ])
    |> validate_required([:name, :description, :moment_id])
  end
end
