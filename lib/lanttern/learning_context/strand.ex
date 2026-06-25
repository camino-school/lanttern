defmodule Lanttern.LearningContext.Strand do
  @moduledoc """
  The `Strand` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext
  import Lanttern.SchemaHelpers

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.StaffMember
  alias Lanttern.Strands.ClassAssignment
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          description: String.t(),
          assessment_info: String.t(),
          teacher_instructions: String.t() | nil,
          cover_image_url: String.t(),
          subject_id: pos_integer(),
          subjects_ids: [pos_integer()],
          year_id: pos_integer(),
          years_ids: [pos_integer()],
          is_starred: boolean(),
          is_locked: boolean(),
          locked_at: DateTime.t() | nil,
          locked_by_staff_member_id: pos_integer() | nil,
          locked_by_staff_member: StaffMember.t() | Ecto.Association.NotLoaded.t() | nil,
          strand_report_id: pos_integer(),
          assessment_points_count: non_neg_integer(),
          report_cycle: Cycle.t(),
          moments: [Moment.t()],
          assessment_points: [AssessmentPoint.t()],
          strand_reports: [StrandReport.t()],
          class_assignments: [ClassAssignment.t()] | Ecto.Association.NotLoaded.t(),
          classes: [Class.t()] | Ecto.Association.NotLoaded.t(),
          subjects: [Subject.t()],
          years: [Year.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "strands" do
    field :name, :string
    field :type, :string
    field :description, :string
    field :assessment_info, :string
    field :teacher_instructions, :string
    field :cover_image_url, :string
    field :is_locked, :boolean, default: false
    field :locked_at, :utc_datetime
    field :subject_id, :id, virtual: true
    field :subjects_ids, {:array, :id}, virtual: true
    field :year_id, :id, virtual: true
    field :years_ids, {:array, :id}, virtual: true
    field :is_starred, :boolean, virtual: true
    field :strand_report_id, :id, virtual: true
    field :assessment_points_count, :integer, virtual: true
    field :report_cycle, :map, virtual: true

    belongs_to :locked_by_staff_member, StaffMember

    has_many :moments, Moment, preload_order: [asc: :position]
    has_many :assessment_points, AssessmentPoint
    has_many :strand_reports, StrandReport
    has_many :class_assignments, ClassAssignment
    has_many :classes, through: [:class_assignments, :class]

    many_to_many :subjects, Subject,
      join_through: "strands_subjects",
      on_replace: :delete

    many_to_many :years, Year,
      join_through: "strands_years",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(strand, attrs) do
    strand
    |> cast(attrs, [
      :name,
      :type,
      :description,
      :assessment_info,
      :teacher_instructions,
      :cover_image_url,
      :subjects_ids,
      :years_ids
    ])
    |> validate_required([:name, :description])
    |> put_subjects()
    |> put_years()
  end

  @doc """
  Changeset for toggling the strand lock (`is_locked`) and its provenance.

  Intentionally separate from `changeset/2`: `is_locked` (and the `locked_at` /
  `locked_by_staff_member_id` provenance) is never castable through regular content
  edits, only through this changeset (gated by the `strand_lock_management` permission
  at the context level).

  On lock (`is_locked: true`) it stamps `locked_at` and keeps the
  `locked_by_staff_member_id` supplied by the caller; on unlock it clears both.
  """
  def lock_changeset(strand, attrs) do
    strand
    |> cast(attrs, [:is_locked, :locked_by_staff_member_id])
    |> validate_required([:is_locked])
    |> put_lock_provenance()
  end

  defp put_lock_provenance(changeset) do
    if get_field(changeset, :is_locked) do
      put_change(changeset, :locked_at, DateTime.truncate(DateTime.utc_now(), :second))
    else
      changeset
      |> put_change(:locked_at, nil)
      |> put_change(:locked_by_staff_member_id, nil)
    end
  end

  def delete_changeset(strand) do
    strand
    |> cast(%{}, [])
    |> foreign_key_constraint(
      :id,
      name: :moments_strand_id_fkey,
      message: gettext("Strand has linked moments.")
    )
    |> foreign_key_constraint(
      :id,
      name: :assessment_points_strand_id_fkey,
      message: gettext("Strand has linked assessment points.")
    )
  end
end
