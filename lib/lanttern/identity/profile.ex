defmodule Lanttern.Identity.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :type, :string
    field :current_locale, :string, default: "en"

    # used to optimize session user, avoiding
    # student, teacher, and school structs preloads
    field :name, :string, virtual: true
    field :school_id, :id, virtual: true
    field :school_name, :string, virtual: true

    belongs_to :user, Lanttern.Identity.User
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :teacher, Lanttern.Schools.Teacher

    has_one :settings, Lanttern.Personalization.ProfileSettings

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
