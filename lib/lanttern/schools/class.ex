defmodule Lanttern.Schools.Class do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  schema "classes" do
    field :name, :string
    field :students_ids, {:array, :id}, virtual: true
    field :years_ids, {:array, :id}, virtual: true

    belongs_to :school, Lanttern.Schools.School
    belongs_to :cycle, Lanttern.Schools.Cycle

    many_to_many :students, Lanttern.Schools.Student,
      join_through: "classes_students",
      on_replace: :delete,
      preload_order: [asc: :name]

    many_to_many :years, Lanttern.Taxonomy.Year,
      join_through: "classes_years",
      on_replace: :delete,
      preload_order: [asc: :id]

    timestamps()
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:name, :school_id, :students_ids, :years_ids, :cycle_id])
    |> validate_required([:name, :school_id, :cycle_id])
    |> foreign_key_constraint(
      :cycle_id,
      name: :classes_cycle_id_fkey,
      message: "Check if the cycle exists and belongs to the same school"
    )
    |> put_students()
    |> put_years()
  end

  defp put_students(changeset) do
    put_students(
      changeset,
      get_change(changeset, :students_ids)
    )
  end

  defp put_students(changeset, nil), do: changeset

  defp put_students(changeset, students_ids) do
    students =
      from(s in Lanttern.Schools.Student, where: s.id in ^students_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:students, students)
  end

  defp put_years(changeset) do
    put_years(
      changeset,
      get_change(changeset, :years_ids)
    )
  end

  defp put_years(changeset, nil), do: changeset

  defp put_years(changeset, years_ids) do
    years =
      from(y in Lanttern.Taxonomy.Year, where: y.id in ^years_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:years, years)
  end
end
