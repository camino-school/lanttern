defmodule Lanttern.ILP.ILPTemplateAILayer do
  @moduledoc """
  The `ILPTemplateAILayer` schema.

  It is an extension of the `ILPTemplate` schema, and is expected to be
  handled only via `cast_assoc` in the `ILPTemplate` changeset.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPTemplate

  @type t :: %__MODULE__{
          template_id: pos_integer(),
          revision_instructions: String.t() | nil,
          model: String.t() | nil,
          cooldown_minutes: non_neg_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "ilp_template_ai_layers" do
    field :revision_instructions, :string
    field :model, :string
    field :cooldown_minutes, :integer, default: 0

    belongs_to :template, ILPTemplate, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(ilp_template_ai_layer, attrs) do
    ilp_template_ai_layer
    |> cast(attrs, [:template_id, :revision_instructions, :model, :cooldown_minutes])

    # template_id is required, but as the schema is expected to be handled only
    # via cast_assoc, we don't need to validate it here
  end
end
