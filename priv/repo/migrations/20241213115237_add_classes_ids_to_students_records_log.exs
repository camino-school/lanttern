defmodule Lanttern.Repo.Migrations.AddClassesIdsToStudentsRecordsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:students_records, prefix: @prefix) do
      add :classes_ids, {:array, :bigint}
    end
  end
end
