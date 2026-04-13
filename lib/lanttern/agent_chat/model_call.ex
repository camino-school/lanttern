defmodule Lanttern.AgentChat.ModelCall do
  @moduledoc """
  LLM calls info schema.

  Stores one row per assistant response for token accounting.

  ## `model` field

  Persists the raw model identifier as configured by the caller (args,
  school AI config, or the app default) — not the normalized
  `"provider:model"` value sent to the provider by `Lanttern.LLM`. This is
  intentional: `model` reflects the *configuration in effect* at the time,
  which is the auditable value; the actual request string is a
  deterministic derivation of it. Analytics that roll up by model should
  normalize on read (or treat `"gpt-4o"` and `"openai:gpt-4o"` as the same
  bucket).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.AgentChat.Message

  @type t :: %__MODULE__{
          id: pos_integer(),
          prompt_tokens: non_neg_integer(),
          completion_tokens: non_neg_integer(),
          model: String.t() | nil,
          message_id: pos_integer(),
          message: Message.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "llm_calls" do
    field :prompt_tokens, :integer, default: 0
    field :completion_tokens, :integer, default: 0
    field :model, :string

    belongs_to :message, Message

    timestamps()
  end

  @doc false
  def changeset(model_calls, attrs) do
    model_calls
    |> cast(attrs, [:prompt_tokens, :completion_tokens, :model, :message_id])
    |> validate_required([:message_id])
  end
end
