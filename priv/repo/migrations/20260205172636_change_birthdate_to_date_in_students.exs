defmodule Lanttern.Repo.Migrations.ChangeBirthdateToDateInStudents do
  use Ecto.Migration

  def up do
    # Convert existing timestamp values to date
    execute("ALTER TABLE students ALTER COLUMN birthdate TYPE date USING (birthdate::date);")
  end

  def down do
    # Convert date back to timestamp at midnight (no timezone info); adjust if you prefer UTC
    execute(
      "ALTER TABLE students ALTER COLUMN birthdate TYPE timestamp USING (birthdate::timestamp);"
    )
  end
end
