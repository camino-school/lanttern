defmodule Lanttern.StudentsInsights.StudentInsight do
  @moduledoc """
  The `StudentInsight` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Identity.User
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
          student: Student.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_insights" do
    field :description, :string

    belongs_to :author, StaffMember
    belongs_to :school, School

    belongs_to :student, Student

    timestamps()
  end

  @doc false
  def changeset(student_insight, attrs, current_user) do
    student_insight
    |> cast(attrs, [:description, :student_id])
    |> put_change(:author_id, current_user.current_profile.staff_member_id)
    |> put_change(:school_id, current_user.current_profile.school_id)
    |> validate_required([:description, :author_id, :school_id, :student_id])
    |> validate_length(:description,
      max: 280,
      message: gettext("Description must be 280 characters or less")
    )
  end


  def validate_ownership(
        %User{current_profile: %{staff_member_id: staff_member_id}},
        %__MODULE__{author_id: author_id}
      )
      when staff_member_id == author_id,
      do: :ok

  def validate_ownership(_current_user, _student_insight),
    do: {:error, :unauthorized}
end
