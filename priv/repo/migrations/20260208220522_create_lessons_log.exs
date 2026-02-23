defmodule Lanttern.Repo.Migrations.CreateLessonsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:lessons, prefix: @prefix) do
      add :lesson_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false
      add :name, :text, null: false
      add :description, :text
      add :teacher_notes, :text
      add :differentiation_notes, :text
      add :is_published, :boolean, null: false, default: false
      add :position, :integer, null: false
      add :strand_id, :bigint, null: false
      add :moment_id, :bigint
      add :subjects_ids, {:array, :bigint}
      add :tags_ids, {:array, :bigint}
      add :is_ai_agent, :boolean, null: false, default: false

      timestamps(updated_at: false)
    end

    create constraint(
             :lessons,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )

    create index(:lessons, [:lesson_id], prefix: @prefix)
  end
end
