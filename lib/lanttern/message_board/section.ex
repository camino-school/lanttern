defmodule Lanttern.MessageBoard.Section do
  @moduledoc """
  The `Sections` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sections" do
    field :name, :string
    field :position, :integer, default: 0

    belongs_to :school, Lanttern.Schools.School
    has_many :messages, Lanttern.MessageBoard.Message

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :position, :school_id])
    |> validate_required([:name, :position, :school_id])
    |> unique_constraint([:name, :school_id], message: "section name must be unique within a school")
  end
end
