defmodule Lanttern.Repo.Migrations.DropPrivateDescAndAddFromAndToDatetimeInStudentRecordReports do
  use Ecto.Migration

  def up do
    alter table(:student_record_reports) do
      remove :private_description
      add :from_datetime, :utc_datetime
      add :to_datetime, :utc_datetime
    end

    # Set to_datetime to be the same as inserted_at for all existing records
    execute "UPDATE student_record_reports SET to_datetime = inserted_at"

    # Now make to_datetime not null
    alter table(:student_record_reports) do
      modify :to_datetime, :utc_datetime, null: false
    end
  end

  def down do
    alter table(:student_record_reports) do
      remove :from_datetime
      remove :to_datetime
      add :private_description, :text
    end
  end
end
