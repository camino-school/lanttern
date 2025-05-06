defmodule Lanttern.Repo.Migrations.CreateStudentRecordReports do
  use Ecto.Migration

  def change do
    create table(:student_record_reports) do
      add :description, :text, null: false
      add :private_description, :text
      add :student_id, references(:students, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:student_record_reports, [:student_id])
  end
end
