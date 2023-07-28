defmodule Lanttern.Schools.Student do
  use Ecto.Schema
  import Ecto.Changeset

  schema "students" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(student, attrs) do
    student
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
