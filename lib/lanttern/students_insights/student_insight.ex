defmodule Lanttern.StudentsInsights.StudentInsight do
  @moduledoc """
  The `StudentInsight` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.School
  alias Lanttern.Schools.StaffMember
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          author: StaffMember.t(),
          author_id: pos_integer(),
          school: School.t(),
          school_id: pos_integer(),
          students: [Student.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_insights" do
    field :description, :string

    belongs_to :author, StaffMember
    belongs_to :school, School

    many_to_many :students, Student,
      join_through: "students_students_insights",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(student_insight, attrs) do
    student_insight
    |> cast(attrs, [
      :description,
      :author_id,
      :school_id
    ])
    |> validate_required([
      :description,
      :author_id,
      :school_id
    ])
    |> validate_length(:description,
      max: 280,
      message: gettext("Description must be 280 characters or less")
    )
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:school_id)
    |> put_students(attrs)
    |> validate_students_required()
  end

  defp put_students(changeset, %{students: students}) when is_list(students) do
    put_assoc(changeset, :students, students)
  end

  defp put_students(changeset, _attrs), do: changeset

  defp validate_students_required(changeset) do
    students = get_field(changeset, :students)

    case students do
      [] -> add_error(changeset, :students, gettext("at least one student must be linked"))
      nil -> add_error(changeset, :students, gettext("at least one student must be linked"))
      [_ | _] -> changeset
    end
  end
end
