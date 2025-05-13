defmodule Lanttern.StudentRecordReports.StudentRecordReport do
  @moduledoc """
  The `StudentRecordReport` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          from_datetime: DateTime.t() | nil,
          to_datetime: DateTime.t(),
          student: Student.t() | Ecto.Association.NotLoaded.t(),
          student_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_record_reports" do
    field :description, :string
    field :from_datetime, :utc_datetime
    field :to_datetime, :utc_datetime

    belongs_to :student, Student

    timestamps()
  end

  @doc false
  def changeset(student_record_report, attrs) do
    student_record_report
    |> cast(attrs, [
      :description,
      :from_datetime,
      :to_datetime,
      :student_id
    ])
    |> validate_required([:description, :student_id])
    |> maybe_put_to_datetime()
  end

  # Set to_datetime to current UTC time if not provided
  defp maybe_put_to_datetime(%{changes: %{to_datetime: _}} = changeset), do: changeset

  defp maybe_put_to_datetime(changeset),
    do: put_change(changeset, :to_datetime, %{DateTime.utc_now() | microsecond: {0, 0}})
end
