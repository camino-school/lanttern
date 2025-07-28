defmodule Lanttern.MessageBoard.CardMessage do
  @moduledoc """
  The `CardMessage` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "card_messages" do
    field :title, :string
    field :cover, :string
    field :color, :string
    field :subtitle, :string
    field :content, :string

    belongs_to :card_section, Lanttern.MessageBoard.CardSection

    timestamps()
  end

  @doc false
  def changeset(card_message, attrs) do
    card_message
    |> cast(attrs, [:title, :subtitle, :content, :color, :cover, :card_section_id])
    |> validate_required([:title, :content, :card_section_id])
  end
end
