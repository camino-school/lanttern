defmodule Lanttern.Repo.Migrations.FixStudentsCycleInfoNullConstraints do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE students_cycle_info ALTER COLUMN student_id SET NOT NULL",
            "ALTER TABLE students_cycle_info ALTER COLUMN student_id DROP NOT NULL"

    execute "ALTER TABLE students_cycle_info ALTER COLUMN cycle_id SET NOT NULL",
            "ALTER TABLE students_cycle_info ALTER COLUMN cycle_id DROP NOT NULL"

    execute "ALTER TABLE students_cycle_info ALTER COLUMN school_id SET NOT NULL",
            "ALTER TABLE students_cycle_info ALTER COLUMN school_id DROP NOT NULL"
  end
end
