defmodule Lanttern.Repo.Migrations.AdjustProfilesForGuardianSupport do
  use Ecto.Migration

  # 1. adjust unique constraints. do not allow more than one profile per student/teacher
  # 2. add guardian_of_student_id column (for guardian profiles)
  # 3. constraints: we can have more than one guardian for each student (so it's unique on user_id/guardian_of_student_id)
  # 4. adjust required_type_related_foreign_key to support guardians

  def change do
    # 1. adjust unique constraints. do not allow more than one profile per student/teacher
    drop unique_index(:profiles, [:student_id, :user_id])
    drop unique_index(:profiles, [:teacher_id, :user_id])
    create unique_index(:profiles, :student_id)
    create unique_index(:profiles, :teacher_id)

    alter table(:profiles) do
      # 2. add guardian_of_student_id column (for guardian profiles)
      add :guardian_of_student_id, references(:students, on_delete: :nothing)
    end

    # 3. constraints: we can have more than one guardian for each student
    create unique_index(:profiles, [:guardian_of_student_id, :user_id])

    # 4. adjust required_type_related_foreign_key to support guardians

    # student_id is required when type = 'student'
    # teacher_id is required when type = 'teacher'
    # guardian_of_student_id is required when type = 'guardian'
    check_constraint = """
    (type = 'student' AND student_id IS NOT NULL AND teacher_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'teacher' AND teacher_id IS NOT NULL AND student_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'guardian' AND guardian_of_student_id IS NOT NULL AND teacher_id IS NULL AND student_id IS NULL)
    """

    drop constraint(:profiles, :required_type_related_foreign_key)

    create constraint(
             :profiles,
             :required_type_related_foreign_key,
             check: check_constraint
           )
  end

  def down do
    # 4. adjust required_type_related_foreign_key to support guardians

    # student_id is required when type = 'student'
    # teacher_id is required when type = 'teacher'
    check_constraint = """
    (type = 'student' AND student_id IS NOT NULL AND teacher_id IS NULL)
    OR (type = 'teacher' AND teacher_id IS NOT NULL AND student_id IS NULL)
    """

    drop constraint(:profiles, :required_type_related_foreign_key)

    create constraint(
             :profiles,
             :required_type_related_foreign_key,
             check: check_constraint
           )

    # 3. constraints: we can have more than one guardian for each student
    drop unique_index(:profiles, [:guardian_of_student_id, :user_id])

    alter table(:profiles) do
      # 2. add guardian_of_student_id column (for guardian profiles)
      remove :guardian_of_student_id, references(:students, on_delete: :nothing)
    end

    # 1. adjust unique constraints. do not allow more than one profile per student/teacher
    drop unique_index(:profiles, :teacher_id)
    drop unique_index(:profiles, :student_id)
    create unique_index(:profiles, [:teacher_id, :user_id])
    create unique_index(:profiles, [:student_id, :user_id])
  end
end
