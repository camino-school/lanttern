defmodule Lanttern.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :type, :text, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :student_id, references(:students, on_delete: :nothing)
      add :teacher_id, references(:teachers, on_delete: :nothing)

      timestamps()
    end

    create index(:profiles, [:user_id])
    create unique_index(:profiles, [:student_id, :user_id])
    create unique_index(:profiles, [:teacher_id, :user_id])

    # student_id is required when type = 'student'
    # teacher_id is required when type = 'teacher'
    check_constraint = """
    (type = 'student' AND student_id IS NOT NULL AND teacher_id IS NULL)
    OR (type = 'teacher' AND teacher_id IS NOT NULL AND student_id IS NULL)
    """

    create constraint(
             :profiles,
             :required_type_related_foreign_key,
             check: check_constraint
           )
  end
end
