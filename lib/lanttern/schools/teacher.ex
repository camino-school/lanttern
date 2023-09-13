defmodule Lanttern.Schools.Teacher do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teachers" do
    field :name, :string

    belongs_to :school, Lanttern.Schools.School

    timestamps()
  end

  @doc false
  def changeset(teacher, attrs) do
    teacher
    |> cast(attrs, [:name, :school_id])
    |> validate_required([:name, :school_id])
  end
end
