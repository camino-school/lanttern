defmodule Lanttern.Repo.Migrations.AddBirthdateToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :birthdate, :utc_datetime
    end
  end
end
