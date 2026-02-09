defmodule Lanttern.Schools.Guardian do
  @moduledoc """
  The `Guardian` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          school_id: pos_integer() | nil,
          school: Lanttern.Schools.School.t() | Ecto.Association.NotLoaded.t(),
          students: [Student.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "guardians" do
    field :name, :string
    field :school_id, :id

    belongs_to :school, Lanttern.Schools.School

    many_to_many :students, Student,
      join_through: "students_guardians",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(guardian, attrs) do
    guardian
    |> cast(attrs, [:name, :school_id])
    |> validate_required([:name, :school_id])
  end
end
