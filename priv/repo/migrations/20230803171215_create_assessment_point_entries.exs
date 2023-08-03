defmodule Lanttern.Repo.Migrations.CreateAssessmentPointEntries do
  use Ecto.Migration

  def change do
    create table(:assessment_point_entries) do
      add :observation, :text
      add :score, :float
      add :assessment_point_id, references(:assessment_points, on_delete: :nothing), null: false
      add :student_id, references(:students, on_delete: :nothing), null: false
      add :ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      timestamps()
    end

    create index(:assessment_point_entries, [:assessment_point_id])
    create index(:assessment_point_entries, [:student_id])
    create index(:assessment_point_entries, [:ordinal_value_id])
    create unique_index(:assessment_point_entries, [:assessment_point_id, :student_id])
  end
end
