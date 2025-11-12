defmodule Lanttern.MessageBoard.MessageAttachment do
  @moduledoc """
  The `MessageAttachment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.Identity.Profile
  alias Lanttern.MessageBoard.Message

  schema "message_attachments" do
    field :position, :integer, default: 0

    belongs_to :owner, Profile
    belongs_to :message, Message
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(message_attachment, attrs) do
    message_attachment
    |> cast(attrs, [:position, :owner_id, :message_id, :attachment_id])
    |> validate_required([:owner_id, :message_id, :attachment_id])
  end
end
