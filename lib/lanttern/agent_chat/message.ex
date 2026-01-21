defmodule Lanttern.AgentChat.Message do
  @moduledoc """
  Agent conversation messages schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.AgentChat.Conversation

  @type t :: %__MODULE__{
          id: pos_integer(),
          role: String.t(),
          content: String.t() | nil,
          conversation_id: pos_integer(),
          conversation: Conversation.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "agent_messages" do
    field :role, :string
    field :content, :string

    belongs_to :conversation, Conversation

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :content, :conversation_id])
    |> validate_required([:role, :conversation_id])
  end
end
