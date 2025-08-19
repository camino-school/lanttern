defmodule Lanttern.Repo.Migrations.CreateStudentsStudentsInsights do
  use Ecto.Migration

  def change do
    create table(:students_students_insights, primary_key: false) do
      add :student_id, references(:students, on_delete: :delete_all), null: false
      add :student_insight_id, references(:students_insights, on_delete: :delete_all), null: false
    end

    create unique_index(:students_students_insights, [:student_id, :student_insight_id])
    create index(:students_students_insights, [:student_insight_id])
  end
end
