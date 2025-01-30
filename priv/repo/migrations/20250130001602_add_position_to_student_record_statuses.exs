defmodule Lanttern.Repo.Migrations.AddPositionToStudentRecordStatuses do
  use Ecto.Migration

  def change do
    alter table(:student_record_statuses) do
      add :position, :integer, default: 0
    end

    create index(:student_record_statuses, [:position])
  end
end
