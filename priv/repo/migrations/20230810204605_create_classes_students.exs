defmodule Lanttern.Repo.Migrations.CreateClassesStudents do
  use Ecto.Migration

  def change do
    create table(:classes_students, primary_key: false) do
      add :class_id, references(:classes)
      add :student_id, references(:students)
    end

    create index(:classes_students, [:class_id])
    create index(:classes_students, [:student_id])
    create unique_index(:classes_students, [:class_id, :student_id])
  end
end
