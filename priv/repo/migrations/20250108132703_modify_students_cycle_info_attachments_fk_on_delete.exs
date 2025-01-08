defmodule Lanttern.Repo.Migrations.ModifyStudentsCycleInfoAttachmentsFkOnDelete do
  use Ecto.Migration

  def change do
    alter table(:students_cycle_info_attachments) do
      modify :student_cycle_info_id, references(:students_cycle_info, on_delete: :delete_all),
        from: references(:students_cycle_info, on_delete: :nothing)

      modify :attachment_id, references(:attachments, on_delete: :delete_all),
        from: references(:attachments, on_delete: :nothing)
    end
  end
end
