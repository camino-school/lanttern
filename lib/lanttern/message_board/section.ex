defmodule Lanttern.MessageBoard.Section do
  @moduledoc """
  The `Sections` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sections" do
    field :name, :string
    field :position, :integer, default: 0

    has_many :messages, Lanttern.MessageBoard.Message

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :position])
    |> validate_required([:name, :position])
  end
end
