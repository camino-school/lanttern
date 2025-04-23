defmodule Lanttern.StudentTags.StudentTagRelationship do
  @moduledoc """
  The `StudentTags.StudentTagRelationship` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_tags" do
    belongs_to :student, Lanttern.Schools.Student, primary_key: true
    belongs_to :tag, Lanttern.StudentTags.Tag, primary_key: true
    belongs_to :school, Lanttern.Schools.School
  end

  @doc false
  def changeset(assignee, attrs) do
    assignee
    |> cast(attrs, [:student_id, :tag_id, :school_id])
    |> validate_required([:student_id, :tag_id, :school_id])
  end
end
