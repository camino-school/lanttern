defmodule Lanttern.Repo.Migrations.CreateAssessmentPoints do
  use Ecto.Migration

  def change do
    create table(:assessment_points) do
      add :name, :text, null: false
      add :date, :utc_datetime, null: false, default: fragment("now()")
      add :description, :text
      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing), null: false
      add :scale_id, references(:grading_scales, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:assessment_points, [:curriculum_item_id])
    create index(:assessment_points, [:scale_id])
  end
end
