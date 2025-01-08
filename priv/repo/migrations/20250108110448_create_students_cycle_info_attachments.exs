defmodule Lanttern.Repo.Migrations.CreateStudentsCycleInfoAttachments do
  use Ecto.Migration

  def change do
    create table(:students_cycle_info_attachments) do
      add :position, :integer, default: 0, null: false
      add :is_family, :boolean, default: false, null: false

      add :student_cycle_info_id, references(:students_cycle_info, on_delete: :nothing),
        null: false

      add :attachment_id, references(:attachments, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:students_cycle_info_attachments, [:student_cycle_info_id])

    create unique_index(:students_cycle_info_attachments, [:attachment_id, :student_cycle_info_id])

    create index(:students_cycle_info_attachments, [:position])
  end
end
