defmodule Lanttern.Repo.Migrations.CreateLessonsAttachments do
  use Ecto.Migration

  def change do
    create table(:lessons_attachments) do
      add :position, :integer, default: 0, null: false
      add :is_teacher_only_resource, :boolean, default: true, null: false
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :attachment_id, references(:attachments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:lessons_attachments, [:lesson_id])
    create unique_index(:lessons_attachments, [:attachment_id, :lesson_id])
    create index(:lessons_attachments, [:position])
  end
end
