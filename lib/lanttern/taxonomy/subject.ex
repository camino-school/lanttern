defmodule Lanttern.Taxonomy.Subject do
  @moduledoc """
  The `Subject` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Curricula.CurriculumItem

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          short_name: String.t(),
          code: String.t(),
          curriculum_items: [CurriculumItem.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "subjects" do
    field :name, :string
    field :short_name, :string
    field :code, :string

    many_to_many :curriculum_items, CurriculumItem, join_through: "curriculum_items_subjects"

    timestamps()
  end

  @doc false
  def changeset(subject, attrs) do
    subject
    |> cast(attrs, [:name, :short_name, :code])
    |> validate_required([:name])
  end
end
