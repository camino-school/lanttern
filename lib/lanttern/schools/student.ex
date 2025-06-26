defmodule Lanttern.Schools.Student do
  @moduledoc """
  The `Student` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.GradesReports.StudentGradesReportEntry
  alias Lanttern.Identity.Profile
  alias Lanttern.ILP.StudentILP
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo
  alias Lanttern.StudentTags.StudentTagRelationship
  alias Lanttern.StudentTags.Tag

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          profile_picture_url: String.t(),
          classes_ids: [pos_integer()],
          has_diff_rubric: boolean(),
          school: School.t(),
          school_id: pos_integer(),
          classes: [Class.t()],
          assessment_point_entries: [AssessmentPointEntry.t()],
          cycles_info: [StudentCycleInfo.t()],
          student_report_cards: [StudentReportCard.t()],
          grades_report_entries: [StudentGradesReportEntry.t()],
          ilps: [StudentILP.t()],
          tags: [Tag.t()],
          profile: Profile.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students" do
    field :name, :string
    field :profile_picture_url, :string
    field :deactivated_at, :utc_datetime

    field :classes_ids, {:array, :id}, virtual: true
    field :has_diff_rubric, :boolean, virtual: true, default: false
    field :tags_ids, {:array, :id}, virtual: true

    # this field is used in the context of student form,
    # and handled by student create and update functions
    field :email, :string, virtual: true

    belongs_to :school, School

    many_to_many :classes, Class,
      join_through: "classes_students",
      on_replace: :delete,
      preload_order: [asc: :name]

    many_to_many :tags, Tag,
      join_through: "students_tags",
      join_keys: [student_id: :id, tag_id: :id],
      preload_order: [asc: :position]

    has_many :assessment_point_entries, AssessmentPointEntry
    has_many :cycles_info, StudentCycleInfo
    has_many :student_report_cards, StudentReportCard
    has_many :grades_report_entries, Lanttern.GradesReports.StudentGradesReportEntry
    has_many :ilps, StudentILP
    has_many :student_tag_relationships, StudentTagRelationship, on_replace: :delete

    has_one :profile, Profile

    timestamps()
  end

  @doc false
  def changeset(student, attrs) do
    student
    |> cast(attrs, [
      :name,
      :profile_picture_url,
      :deactivated_at,
      :school_id,
      :classes_ids,
      :tags_ids
    ])
    |> validate_required([:name, :school_id])
    |> put_classes(attrs)
    |> cast_tags()
  end

  defp put_classes(changeset, %{classes: classes}) when is_list(classes),
    do: put_assoc(changeset, :classes, classes)

  defp put_classes(changeset, _attrs) do
    put_classes_ids(
      changeset,
      get_change(changeset, :classes_ids)
    )
  end

  defp put_classes_ids(changeset, nil), do: changeset

  defp put_classes_ids(changeset, classes_ids) do
    classes =
      from(c in Class, where: c.id in ^classes_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:classes, classes)
  end

  def cast_tags(changeset) do
    case get_change(changeset, :tags_ids) do
      tags_ids when is_list(tags_ids) ->
        school_id = get_field(changeset, :school_id)

        tags_relationships_params =
          Enum.map(tags_ids, &%{tag_id: &1, school_id: school_id})

        changeset
        |> put_change(:student_tag_relationships, tags_relationships_params)
        |> cast_assoc(:student_tag_relationships)

      _ ->
        changeset
    end
  end
end
