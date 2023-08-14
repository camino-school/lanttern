defmodule Lanttern.Assessments.AssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_points" do
    field :name, :string
    field :datetime, :utc_datetime
    field :description, :string

    # create assessment point UI fields
    field :date, :date, virtual: true
    field :hour, :integer, virtual: true
    field :minute, :integer, virtual: true

    belongs_to :curriculum_item, Lanttern.Curricula.Item
    belongs_to :scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [:name, :datetime, :description, :curriculum_item_id, :scale_id])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
    |> validate_and_build_datetime_from_ui(attrs)
  end

  defp validate_and_build_datetime_from_ui(changeset, attrs) do
    case changeset.changes do
      %{datetime: _datetime} ->
        # skip if there's already a datetime change
        changeset

      _changes ->
        changeset
        |> cast(attrs, [:date, :hour, :minute])
        |> validate_number(:hour, greater_than_or_equal_to: 0, less_than: 24)
        |> validate_number(:minute, greater_than_or_equal_to: 0, less_than: 60)
        |> build_datetime_from_ui()
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
end
