defmodule Lanttern.MessageBoard.MessageClass do
  @moduledoc """
  The `MessageClass` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.MessageBoard.Message
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School

  @primary_key false
  schema "messages_classes" do
    belongs_to :message, Message, primary_key: true
    belongs_to :class, Class, primary_key: true
    belongs_to :school, School
  end

  @doc false
  def changeset(class_message, attrs) do
    class_message
    |> cast(attrs, [:message_id, :class_id, :school_id])
    |> validate_required([:message_id, :class_id, :school_id])
  end
end
