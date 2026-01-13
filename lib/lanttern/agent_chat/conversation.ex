defmodule Lanttern.AgentChat.Conversation do
  @moduledoc """
  Agent conversation schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.Scope

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t() | nil,
          profile_id: pos_integer(),
          profile: Profile.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "agent_conversations" do
    field :name, :string

    belongs_to :profile, Profile

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs, %Scope{} = scope) do
    conversation
    |> cast(attrs, [:name])
    |> put_change(:profile_id, scope.profile_id)
  end
end
