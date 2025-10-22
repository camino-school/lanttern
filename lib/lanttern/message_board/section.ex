defmodule Lanttern.MessageBoard.Section do
  @moduledoc """
  The `Sections` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.MessageBoard.MessageV2
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          messages: [MessageV2.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "sections" do
    field :name, :string
    field :position, :integer, default: 0
    belongs_to :school, Lanttern.Schools.School

    has_many :messages, Lanttern.MessageBoard.MessageV2,
      preload_order: [asc: :position, desc: :updated_at, asc: :archived_at]

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :position, :school_id])
    |> validate_required([:name, :position, :school_id])
    |> unique_constraint([:name, :school_id],
      message: "section name must be unique within a school"
    )
  end
end
