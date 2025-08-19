defmodule Lanttern.StudentsInsights.StudentInsight do
  @moduledoc """
  The `StudentInsight` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.School
  alias Lanttern.Schools.StaffMember

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          author: StaffMember.t(),
          author_id: pos_integer(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_insights" do
    field :description, :string

    belongs_to :author, StaffMember
    belongs_to :school, School

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
  end
end
