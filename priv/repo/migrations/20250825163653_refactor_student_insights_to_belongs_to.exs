defmodule Lanttern.Repo.Migrations.RefactorStudentInsightsToBelongsTo do
  use Ecto.Migration

  def change do
    alter table(:students_insights) do
      add :student_id, references(:students, on_delete: :nothing), null: false
    end

    create index(:students_insights, [:student_id])

    drop table(:students_students_insights)
  end
end
