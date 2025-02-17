defmodule Lanttern.Repo.Migrations.AddDeactivatedAtToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :deactivated_at, :utc_datetime
    end
  end
end
