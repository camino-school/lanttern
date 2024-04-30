defmodule Lanttern.Curricula.Curriculum do
  @moduledoc """
  The `Curriculum` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "curricula" do
    field :name, :string
    field :code, :string
    field :description, :string

    timestamps()
  end

  @doc false
  def changeset(curriculum, attrs) do
    curriculum
    |> cast(attrs, [:name, :code, :description])
    |> validate_required([:name])
  end
end
