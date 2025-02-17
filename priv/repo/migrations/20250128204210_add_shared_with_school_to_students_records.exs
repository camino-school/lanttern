defmodule Lanttern.Repo.Migrations.AddSharedWithSchoolToStudentsRecords do
  use Ecto.Migration

  def change do
    alter table(:students_records) do
      add :shared_with_school, :boolean, default: false, null: false
    end
  end
end
