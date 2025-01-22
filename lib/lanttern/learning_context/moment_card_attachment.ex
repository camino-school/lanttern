defmodule Lanttern.LearningContext.MomentCardAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.Attachments.Attachment

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          shared_with_students: boolean(),
          moment_card: MomentCard.t() | Ecto.Association.NotLoaded.t(),
          moment_card_id: pos_integer(),
          attachment: Attachment.t() | Ecto.Association.NotLoaded.t(),
          attachment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "moment_cards_attachments" do
    field :position, :integer, default: 0
    field :shared_with_students, :boolean, default: false

    belongs_to :moment_card, MomentCard
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(moment_card_attachment, attrs) do
    moment_card_attachment
    |> cast(attrs, [:position, :shared_with_students, :moment_card_id, :attachment_id])
    |> validate_required([:position, :shared_with_students, :moment_card_id, :attachment_id])
  end
end
