defmodule Lanttern.Repo.Migrations.AddInternalNotesToStudentsRecords do
  use Ecto.Migration

  def change do
    alter table(:students_records) do
      add :internal_notes, :text
    end
  end
end
