defmodule Lanttern.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback) do
      add :comment, :text, null: false
      add :profile_id, references(:profiles, on_delete: :nothing), null: false
      add :student_id, references(:students, on_delete: :nothing), null: false
      add :assessment_point_id, references(:assessment_points, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:feedback, [:profile_id])
    create index(:feedback, [:student_id])
    create unique_index(:feedback, [:assessment_point_id, :student_id])
  end
end
