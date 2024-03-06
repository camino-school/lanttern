defmodule Lanttern.Repo.Migrations.CreateGradeReports do
  use Ecto.Migration

  def change do
    create table(:grade_reports) do
      add :info, :text
      add :is_differentiation, :boolean, null: false, default: false
      add :school_cycle_id, references(:school_cycles, on_delete: :nothing), null: false
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
      add :year_id, references(:years, on_delete: :nothing), null: false
      add :scale_id, references(:grading_scales, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:grade_reports, [:school_cycle_id])
    create index(:grade_reports, [:subject_id])
    create index(:grade_reports, [:year_id])
    create index(:grade_reports, [:scale_id])
  end
end
