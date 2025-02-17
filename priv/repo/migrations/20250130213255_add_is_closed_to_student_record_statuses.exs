defmodule Lanttern.Repo.Migrations.AddIsClosedToStudentRecordStatuses do
  use Ecto.Migration

  def change do
    alter table(:student_record_statuses) do
      add :is_closed, :boolean, default: false
    end
  end
end
