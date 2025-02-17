defmodule Lanttern.Repo.Migrations.AddInternalNotesToStudentsRecordsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:students_records, prefix: @prefix) do
      add :internal_notes, :text
    end
  end
end
