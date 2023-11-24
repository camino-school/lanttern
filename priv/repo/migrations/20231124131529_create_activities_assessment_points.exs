defmodule Lanttern.Repo.Migrations.CreateActivitiesAssessmentPoints do
  use Ecto.Migration

  def change do
    create table(:activities_assessment_points) do
      add :position, :integer, null: false, default: 0
      add :activity_id, references(:activities, on_delete: :delete_all), null: false

      add :assessment_point_id, references(:assessment_points, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:activities_assessment_points, [:activity_id])
    create unique_index(:activities_assessment_points, [:assessment_point_id])
  end
end
