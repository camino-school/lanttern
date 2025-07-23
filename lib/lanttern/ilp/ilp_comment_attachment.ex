defmodule Lanttern.ILP.ILPCommentAttachment do
  @moduledoc """
  Schema for ILP Comment Attachments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.ILP.ILPComment

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: pos_integer(),
          attachment_id: pos_integer(),
          attachment: Attachment.t(),
          ilp_comment_id: pos_integer(),
          ilp_comment: ILPComment.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_comment_attachments" do
    field :position, :integer, default: 0

    belongs_to :attachment, Attachment
    belongs_to :ilp_comment, ILPComment

    timestamps()
  end

  @doc false
  def changeset(ilp_comment_attachment, attrs) do
    ilp_comment_attachment
    |> cast(attrs, [:attachment_id, :ilp_comment_id, :position])
    |> validate_required([:attachment_id, :ilp_comment_id])
  end
end
