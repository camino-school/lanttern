defmodule Lanttern.MessageBoard.MessageClass do
  @moduledoc """
  The `MessageClass` schema (join table) - DEPRECATED

  @deprecated "Will be replaced by Lanttern.MessageBoard.MessageClassV2"
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.MessageBoard.Message
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School

  @primary_key false
  @deprecated "Use Lanttern.MessageBoard.MessageClassV2 instead"
  schema "board_messages_classes" do
    belongs_to :message, Message, primary_key: true
    belongs_to :class, Class, primary_key: true
    belongs_to :school, School
  end

  @doc false
  @deprecated "Use Lanttern.MessageBoard.MessageClassV2.changeset/2 instead"
  def changeset(class_message, attrs) do
    class_message
    |> cast(attrs, [:message_id, :class_id, :school_id])
    |> validate_required([:message_id, :class_id, :school_id])
  end
end
