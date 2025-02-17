defmodule Lanttern.LearningContext.Strand do
  @moduledoc """
  The `Strand` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext
  import Lanttern.SchemaHelpers

  alias Lanttern.LearningContext.Moment
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Notes.Note
  alias Lanttern.Notes.StrandNoteRelationship
  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          description: String.t(),
          teacher_instructions: String.t() | nil,
          cover_image_url: String.t(),
          subject_id: pos_integer(),
          subjects_ids: [pos_integer()],
          year_id: pos_integer(),
          years_ids: [pos_integer()],
          is_starred: boolean(),
          strand_report_id: pos_integer(),
          assessment_points_count: non_neg_integer(),
          report_cycle: Cycle.t(),
          moments: [Moment.t()],
          assessment_points: [AssessmentPoint.t()],
          strand_reports: [StrandReport.t()],
          strand_note_relationships: [StrandNoteRelationship.t()],
          notes: [Note.t()],
          subjects: [Subject.t()],
          years: [Year.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "strands" do
    field :name, :string
    field :type, :string
    field :description, :string
    field :teacher_instructions, :string
    field :cover_image_url, :string
    field :subject_id, :id, virtual: true
    field :subjects_ids, {:array, :id}, virtual: true
    field :year_id, :id, virtual: true
    field :years_ids, {:array, :id}, virtual: true
    field :is_starred, :boolean, virtual: true
    field :strand_report_id, :id, virtual: true
    field :assessment_points_count, :integer, virtual: true
    field :report_cycle, :map, virtual: true

    has_many :moments, Moment
    has_many :assessment_points, AssessmentPoint
    has_many :strand_reports, StrandReport
    has_many :strand_note_relationships, StrandNoteRelationship
    has_many :notes, through: [:strand_note_relationships, :note]

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
      :teacher_instructions,
      :cover_image_url,
      :subjects_ids,
      :years_ids
    ])
    |> validate_required([:name, :description])
    |> put_subjects()
    |> put_years()
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
