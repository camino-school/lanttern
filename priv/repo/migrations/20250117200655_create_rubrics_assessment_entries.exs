defmodule Lanttern.Repo.Migrations.CreateRubricsAssessmentEntries do
  use Ecto.Migration

  def change do
    create table(:rubrics_assessment_entries) do
      add :score, :float
      add :student_score, :float

      add :assessment_point_rubric_id,
          references(:assessment_points_rubrics, on_delete: :nothing),
          null: false

      add :student_id, references(:students, on_delete: :nothing), null: false
      add :ordinal_value_id, references(:ordinal_values, on_delete: :nothing)
      add :student_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      timestamps()
    end

    create index(:rubrics_assessment_entries, [:assessment_point_rubric_id])
    create unique_index(:rubrics_assessment_entries, [:student_id, :assessment_point_rubric_id])
    create index(:rubrics_assessment_entries, [:ordinal_value_id])
    create index(:rubrics_assessment_entries, [:student_ordinal_value_id])
  end
end
