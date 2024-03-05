defmodule Lanttern.Identity.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.User
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
          user: User.t(),
          user_id: pos_integer(),
          student: Student.t(),
          student_id: pos_integer(),
          teacher: Teacher.t(),
          teacher_id: pos_integer(),
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

    belongs_to :user, User
    belongs_to :student, Student
    belongs_to :teacher, Teacher

    has_one :settings, ProfileSettings

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:type, :user_id, :teacher_id, :student_id, :current_locale])
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
