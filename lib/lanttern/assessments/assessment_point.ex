defmodule Lanttern.Assessments.AssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  schema "assessment_points" do
    field :name, :string
    field :datetime, :utc_datetime
    field :description, :string

    # create assessment point UI fields
    field :date, :date, virtual: true
    field :hour, :integer, virtual: true
    field :minute, :integer, virtual: true
    field :classes_ids, {:array, :id}, virtual: true

    belongs_to :curriculum_item, Lanttern.Curricula.Item
    belongs_to :scale, Lanttern.Grading.Scale

    many_to_many :classes, Lanttern.Schools.Class,
      join_through: "assessment_points_classes",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [:name, :datetime, :description, :curriculum_item_id, :scale_id, :classes_ids])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
    |> validate_and_build_datetime_from_ui(attrs)
    |> put_classes()
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
end
