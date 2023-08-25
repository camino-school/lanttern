defmodule Lanttern.Repo.Migrations.AddNotNullToClassesStudentsColumns do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE classes_students ALTER COLUMN class_id SET NOT NULL",
            "ALTER TABLE classes_students ALTER COLUMN class_id DROP NOT NULL"

    execute "ALTER TABLE classes_students ALTER COLUMN student_id SET NOT NULL",
            "ALTER TABLE classes_students ALTER COLUMN student_id DROP NOT NULL"
  end
end
