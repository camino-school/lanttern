defmodule Lanttern.Identity.Profile do
  @moduledoc """
  The `Profile` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.User
  alias Lanttern.Notes.Note
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student
  alias Lanttern.Schools.Teacher
  alias Lanttern.Personalization.ProfileSettings

  @type t :: %__MODULE__{
          id: pos_integer(),
          type: String.t(),
          current_locale: String.t(),
          name: String.t(),
          school_id: pos_integer(),
          school_name: String.t(),
          permissions: [String.t()],
          current_school_cycle: Cycle.t(),
          user: User.t(),
          user_id: pos_integer(),
          student: Student.t(),
          student_id: pos_integer(),
          teacher: Teacher.t(),
          teacher_id: pos_integer(),
          guardian_of_student: Student.t(),
          guardian_of_student_id: pos_integer(),
          notes: [Note.t()],
          settings: ProfileSettings.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "profiles" do
    field :type, :string
    field :current_locale, :string, default: "en"

    # used to optimize session user, avoiding
    # student, teacher, and school structs preloads
    field :name, :string, virtual: true
    field :school_id, :id, virtual: true
    field :school_name, :string, virtual: true
    field :permissions, {:array, :string}, virtual: true, default: []
    field :current_school_cycle, :map, default: nil, virtual: true

    belongs_to :user, User
    belongs_to :student, Student
    belongs_to :teacher, Teacher
    belongs_to :guardian_of_student, Student

    has_many :notes, Note, foreign_key: :author_id

    has_one :settings, ProfileSettings

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :type,
      :user_id,
      :teacher_id,
      :student_id,
      :guardian_of_student_id,
      :current_locale
    ])
    |> validate_required([:type, :user_id])
    |> validate_inclusion(:current_locale, ["en", "pt_BR"], message: "Locale not supported")
    |> validate_type_id()
  end

  defp validate_type_id(changeset) do
    case get_field(changeset, :type) do
      "student" ->
        changeset
        |> validate_required([:student_id])
        |> put_change(:teacher_id, nil)
        |> put_change(:guardian_of_student_id, nil)

      "teacher" ->
        changeset
        |> validate_required([:teacher_id])
        |> put_change(:student_id, nil)
        |> put_change(:guardian_of_student_id, nil)

      "guardian" ->
        changeset
        |> validate_required([:guardian_of_student_id])
        |> put_change(:student_id, nil)
        |> put_change(:teacher_id, nil)

      _ ->
        changeset
        |> add_error(:type, "Type should be student, teacher, or guardian")
    end
  end
end
