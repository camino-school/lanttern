defmodule Lanttern.Repo.Migrations.AddClosedAtToStudentsRecordsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:students_records, prefix: @prefix) do
      add :closed_at, :utc_datetime
      add :closed_by_staff_member_id, :bigint
    end
  end
end
