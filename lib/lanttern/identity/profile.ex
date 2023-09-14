defmodule Lanttern.Identity.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :type, :string

    belongs_to :user, Lanttern.Identity.User
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :teacher, Lanttern.Schools.Teacher

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:type, :user_id, :teacher_id, :student_id])
    |> validate_required([:type, :user_id])
    |> validate_type_id()
  end

  defp validate_type_id(changeset) do
    case get_field(changeset, :type) do
      "student" ->
        changeset
        |> validate_required([:student_id])
        |> put_change(:teacher_id, nil)

      "teacher" ->
        changeset
        |> validate_required([:teacher_id])
        |> put_change(:student_id, nil)

      _ ->
        changeset
        |> add_error(:type, "Type should be student or teacher")
    end
  end
end