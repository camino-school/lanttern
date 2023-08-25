defmodule Lanttern.Assessments.AssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo
  alias Lanttern.Assessments.AssessmentPointEntry

  schema "assessment_points" do
    field :name, :string
    field :datetime, :utc_datetime
    field :description, :string

    # create assessment point UI fields
    field :date, :date, virtual: true
    field :hour, :integer, virtual: true
    field :minute, :integer, virtual: true
    field :class_id, :id, virtual: true
    field :classes_ids, {:array, :id}, virtual: true
    field :student_id, :id, virtual: true
    field :students_ids, {:array, :id}, virtual: true

    belongs_to :curriculum_item, Lanttern.Curricula.CurriculumItem
    belongs_to :scale, Lanttern.Grading.Scale

    has_many :entries, Lanttern.Assessments.AssessmentPointEntry

    many_to_many :classes, Lanttern.Schools.Class,
      join_through: "assessment_points_classes",
      on_replace: :delete

    timestamps()
  end

  @doc """
  An assessment point changeset for registration.

  The main difference between this and the (update) `changeset/2` is that
  in the creation process, we can create entries based on the virtual `students_ids` field.
  """
  def creation_changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [
      :name,
      :datetime,
      :description,
      :curriculum_item_id,
      :scale_id,
      :classes_ids,
      :students_ids
    ])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
    |> validate_and_build_datetime()
    |> put_classes()
    |> cast_entries()
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
      :curriculum_item_id,
      :scale_id,
      :classes_ids
    ])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
    |> validate_and_build_datetime()
    |> put_classes()
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

  defp cast_entries(%{changes: %{students_ids: students_ids}} = changeset) do
    entries_params =
      %{
        entries: Enum.map(students_ids, &%{student_id: &1})
      }

    changeset
    |> cast(entries_params, [])
    |> cast_assoc(:entries, with: &AssessmentPointEntry.blank_changeset/2)
  end

  defp cast_entries(changeset), do: changeset
end
