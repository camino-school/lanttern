defmodule Lanttern.Schools.Student do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  schema "students" do
    field :name, :string
    field :classes_ids, {:array, :id}, virtual: true

    belongs_to :school, Lanttern.Schools.School

    many_to_many :classes, Lanttern.Schools.Class,
      join_through: "classes_students",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(student, attrs) do
    student
    |> cast(attrs, [:name, :school_id, :classes_ids])
    |> validate_required([:name, :school_id])
    |> put_classes()
  end

  defp put_classes(changeset) do
    put_classes(
      changeset,
      get_change(changeset, :classes_ids)
    )
  end

  defp put_classes(changeset, nil), do: changeset

  defp put_classes(changeset, classes_ids) do
    classes =
      from(c in Lanttern.Schools.Class, where: c.id in ^classes_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:classes, classes)
  end
end
