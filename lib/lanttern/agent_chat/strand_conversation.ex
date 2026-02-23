defmodule Lanttern.AgentChat.StrandConversation do
  @moduledoc """
  Links agent conversations to strands and optionally to specific lessons.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.AgentChat.Conversation
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Lessons.Lesson

  @type t :: %__MODULE__{
          conversation_id: pos_integer(),
          conversation: Conversation.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          lesson_id: pos_integer() | nil,
          lesson: Lesson.t() | Ecto.Association.NotLoaded.t() | nil
        }

  @primary_key false
  schema "strand_agent_conversations" do
    belongs_to :conversation, Conversation
    belongs_to :strand, Strand
    belongs_to :lesson, Lesson
  end

  @doc false
  def changeset(strand_conversation, attrs) do
    strand_conversation
    |> cast(attrs, [:conversation_id, :strand_id, :lesson_id])
    |> validate_required([:conversation_id, :strand_id])
  end
end
