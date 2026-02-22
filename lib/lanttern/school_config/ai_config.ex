defmodule Lanttern.SchoolConfig.AiConfig do
  @moduledoc """
  School-level AI configuration schema.

  Stores AI settings at the school level including the default LLM,
  school-wide knowledge base, and guardrails for AI interactions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          base_model: String.t() | nil,
          knowledge: String.t() | nil,
          guardrails: String.t() | nil,
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "school_ai_configs" do
    field :base_model, :string
    field :knowledge, :string
    field :guardrails, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(ai_config, attrs, %Scope{} = scope) do
    ai_config
    |> cast(attrs, [:base_model, :knowledge, :guardrails])
    |> put_change(:school_id, scope.school_id)
    |> unique_constraint(:school_id)
  end
end
