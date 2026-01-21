defmodule Lanttern.AgentChat.Conversation do
  @moduledoc """
  Agent conversation schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.AgentChat.Message
  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t() | nil,
          profile_id: pos_integer(),
          profile: Profile.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          messages: [Message.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "agent_conversations" do
    field :name, :string

    belongs_to :profile, Profile
    belongs_to :school, School
    has_many :messages, Message

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs, %Scope{} = scope) do
    conversation
    |> cast(attrs, [:name])
    |> put_change(:profile_id, scope.profile_id)
    |> put_change(:school_id, scope.school_id)
  end
end
