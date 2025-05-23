defmodule Lanttern.Assessments.AssessmentPoint do
  @moduledoc """
  The `AssessmentPoint` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.Feedback
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Grading.GradeComponent
  alias Lanttern.Grading.Scale
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Class

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          datetime: DateTime.t(),
          description: String.t(),
          report_info: String.t(),
          position: non_neg_integer(),
          is_differentiation: boolean(),
          date: Date.t(),
          hour: non_neg_integer(),
          minute: non_neg_integer(),
          class_id: pos_integer(),
          classes_ids: [pos_integer()],
          student_id: pos_integer(),
          students_ids: [pos_integer()],
          curriculum_item: CurriculumItem.t(),
          curriculum_item_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          rubric: Rubric.t(),
          rubric_id: pos_integer(),
          moment: Moment.t(),
          moment_id: pos_integer(),
          strand: Strand.t(),
          strand_id: pos_integer(),
          entries: [AssessmentPointEntry.t()],
          feedbacks: [Feedback.t()],
          grade_components: [GradeComponent.t()],
          classes: [Class.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "assessment_points" do
    field :name, :string
    field :datetime, :utc_datetime
    field :description, :string
    field :report_info, :string
    field :position, :integer, default: 0
    field :is_differentiation, :boolean, default: false

    # create assessment point UI fields
    field :date, :date, virtual: true
    field :hour, :integer, virtual: true
    field :minute, :integer, virtual: true
    field :class_id, :id, virtual: true
    field :classes_ids, {:array, :id}, virtual: true
    field :student_id, :id, virtual: true
    field :students_ids, {:array, :id}, virtual: true

    field :has_diff_rubric_for_student, :boolean, virtual: true

    belongs_to :curriculum_item, CurriculumItem
    belongs_to :scale, Scale
    belongs_to :rubric, Rubric
    belongs_to :moment, Moment
    belongs_to :strand, Strand

    has_many :entries, AssessmentPointEntry
    has_many :feedbacks, Feedback
    has_many :grade_components, GradeComponent

    many_to_many :classes, Class,
      join_through: "assessment_points_classes",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [
      :name,
      :datetime,
      :date,
      :hour,
      :minute,
      :description,
      :report_info,
      :position,
      :is_differentiation,
      :curriculum_item_id,
      :scale_id,
      :rubric_id,
      :moment_id,
      :strand_id,
      :classes_ids,
      :students_ids
    ])
    |> validate_required([:curriculum_item_id, :scale_id])
    |> validate_and_build_datetime()
    |> put_classes()
    |> cast_entries()
    |> unique_constraint([:strand_id, :curriculum_item_id],
      message: gettext("Curriculum item already added to this strand")
    )
    |> check_constraint(
      :name,
      name: :required_name_except_in_strand_context,
      message: gettext("Name is required")
    )
    |> foreign_key_constraint(
      :rubric_id,
      name: :assessment_points_rubric_id_fkey,
      message:
        gettext(
          "Error linking rubric. Check if it exists and uses the same scale used in the assessment point."
        )
    )
    |> foreign_key_constraint(
      :scale_id,
      name: :assessment_point_entries_scale_id_fkey,
      message:
        gettext(
          "You may already have some entries for this assessment point. Changing the scale when entries exist is not allowed, as it would cause data loss."
        )
    )
  end

  defp validate_and_build_datetime(changeset) do
    case changeset.changes do
      %{datetime: _datetime} ->
        # skip if there's already a datetime change
        changeset

      %{date: _date, hour: _hour, minute: _minute} ->
        # if there're UI fields changes, build datetime based on UI fields changes
        changeset
        |> validate_number(:hour, greater_than_or_equal_to: 0, less_than: 24)
        |> validate_number(:minute, greater_than_or_equal_to: 0, less_than: 60)
        |> build_datetime_from_ui()

      _changes ->
        # else, create UI fields from source data
        changeset
        |> build_datetime_ui_from_data()
    end
  end

  defp build_datetime_from_ui(changeset) do
    case {changeset.valid?, changeset.changes} do
      {true, %{date: date, hour: hour, minute: minute}} ->
        time = Time.new!(hour, minute, 0)
        tz = Timex.Timezone.local().full_name
        datetime = DateTime.new!(date, time, tz)

        changeset
        |> cast(%{datetime: datetime}, [:datetime])

      {_, _} ->
        changeset
    end
  end

  defp build_datetime_ui_from_data(changeset) do
    case get_field(changeset, :datetime) do
      nil ->
        changeset

      datetime ->
        local_datetime = Timex.local(datetime)

        date = local_datetime |> DateTime.to_date()
        time = local_datetime |> DateTime.to_time()

        attrs = %{
          date: date,
          hour: time.hour,
          minute: time.minute
        }

        changeset
        |> cast(attrs, [:date, :hour, :minute])
    end
  end

  defp put_classes(changeset) do
    put_classes(
      changeset,
      get_change(changeset, :classes_ids)
    )
  end

  defp put_classes(changeset, nil), do: changeset

  defp put_classes(changeset, classes_ids) do
    classes =
      from(c in Lanttern.Schools.Class, where: c.id in ^classes_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:classes, classes)
  end

  defp cast_entries(%{valid?: true, changes: %{students_ids: students_ids}} = changeset) do
    scale =
      get_field(changeset, :scale_id)
      |> Lanttern.Grading.get_scale!()

    entries_params =
      %{
        entries:
          Enum.map(
            students_ids,
            &%{
              student_id: &1,
              scale_id: scale.id,
              scale_type: scale.type
            }
          )
      }

    changeset
    |> cast(entries_params, [])
    |> cast_assoc(:entries, with: &AssessmentPointEntry.blank_changeset/2)
  end

  defp cast_entries(changeset), do: changeset

  def delete_changeset(assessment) do
    assessment
    |> cast(%{}, [])
    |> foreign_key_constraint(
      :id,
      name: :assessment_point_entries_assessment_point_id_fkey,
      message: gettext("Assessment point has linked entries.")
    )
  end
end
