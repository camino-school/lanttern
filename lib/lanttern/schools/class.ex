defmodule Lanttern.Schools.Class do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          students_ids: [pos_integer()],
          years_ids: [pos_integer()],
          school: School.t(),
          school_id: pos_integer(),
          cycle: Cycle.t(),
          cycle_id: pos_integer(),
          students: [Student.t()],
          years: [Year.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "classes" do
    field :name, :string
    field :students_ids, {:array, :id}, virtual: true
    field :years_ids, {:array, :id}, virtual: true

    belongs_to :school, School
    belongs_to :cycle, Cycle

    many_to_many :students, Student,
      join_through: "classes_students",
      on_replace: :delete,
      preload_order: [asc: :name]

    many_to_many :years, Year,
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
      from(s in Student, where: s.id in ^students_ids)
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
      from(y in Year, where: y.id in ^years_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:years, years)
  end
end
