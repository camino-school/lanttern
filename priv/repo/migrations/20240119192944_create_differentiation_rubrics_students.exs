defmodule Lanttern.Repo.Migrations.CreateDifferentiationRubricsStudents do
  use Ecto.Migration

  def change do
    create table(:differentiation_rubrics_students, primary_key: false) do
      add :rubric_id, references(:rubrics, on_delete: :delete_all), null: false
      add :student_id, references(:students, on_delete: :delete_all), null: false
    end

    create index(:differentiation_rubrics_students, [:rubric_id])
    create unique_index(:differentiation_rubrics_students, [:student_id, :rubric_id])
  end
end
