defmodule Lanttern.Agents.Agent do
  @moduledoc """
  Base AI agent schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          knowledge: String.t() | nil,
          personality: String.t() | nil,
          guardrails: String.t() | nil,
          instructions: String.t() | nil,
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "ai_agents" do
    field :name, :string
    field :knowledge, :string
    field :personality, :string
    field :guardrails, :string
    field :instructions, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(agent, attrs, %Scope{} = scope) do
    agent
    |> cast(attrs, [:name, :knowledge, :personality, :guardrails, :instructions])
    |> validate_required([:name])
    |> put_change(:school_id, scope.school_id)
  end
end
