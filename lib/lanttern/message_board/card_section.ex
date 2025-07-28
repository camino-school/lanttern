defmodule Lanttern.MessageBoard.CardSection do
  @moduledoc """
  The `CardSection` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "card_sections" do
    field :name, :string

    has_many :messages, Lanttern.MessageBoard.CardMessage

    timestamps()
  end

  @doc false
  def changeset(card_section, attrs) do
    card_section
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
