defmodule Lanttern.LessonTemplates.LessonTemplate do
  @moduledoc """
  Lesson template schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          about: String.t() | nil,
          template: String.t() | nil,
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "lesson_templates" do
    field :name, :string
    field :about, :string
    field :template, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(lesson_template, attrs, %Scope{} = scope) do
    lesson_template
    |> cast(attrs, [:name, :about, :template])
    |> validate_required([:name])
    |> put_change(:school_id, scope.school_id)
  end
end
