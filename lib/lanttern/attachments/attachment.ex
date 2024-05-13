defmodule Lanttern.Attachments.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          link: String.t(),
          is_external: boolean(),
          owner: Profile.t(),
          owner_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "attachments" do
    field :name, :string
    field :link, :string
    field :description, :string
    field :is_external, :boolean, default: false

    belongs_to :owner, Profile

    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :description, :link, :is_external, :owner_id])
    |> validate_required([:name, :link, :owner_id])
  end
end
