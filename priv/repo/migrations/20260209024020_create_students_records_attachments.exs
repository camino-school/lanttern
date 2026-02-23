defmodule Lanttern.Repo.Migrations.CreateStudentsRecordsAttachments do
  use Ecto.Migration

  def change do
    create table(:students_records_attachments) do
      add :position, :integer, default: 0, null: false
      add :student_record_id, references(:students_records, on_delete: :delete_all), null: false
      add :attachment_id, references(:attachments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:students_records_attachments, [:student_record_id])
    create unique_index(:students_records_attachments, [:attachment_id])
  end
end
