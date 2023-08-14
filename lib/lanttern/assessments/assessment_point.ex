defmodule Lanttern.Assessments.AssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_points" do
    field :name, :string
    field :date, :utc_datetime
    field :description, :string

    field :datetime_ui, :naive_datetime, default: NaiveDateTime.utc_now(:second), virtual: true

    belongs_to :curriculum_item, Lanttern.Curricula.Item
    belongs_to :scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast_date(attrs)
    |> cast(attrs, [:name, :description, :curriculum_item_id, :scale_id])
    |> validate_required([:name, :curriculum_item_id, :scale_id])
  end

  defp cast_date(assessment, %{"datetime_ui" => datetime_ui} = _attrs) do
    assessment
    |> cast(%{"date" => datetime_ui}, [:date])
  end

  defp cast_date(assessment, attrs) do
    assessment
    |> cast(attrs, [:date])
  end
end
