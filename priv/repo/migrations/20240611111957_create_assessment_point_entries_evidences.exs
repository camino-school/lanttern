defmodule Lanttern.Repo.Migrations.CreateAssessmentPointEntriesEvidences do
  use Ecto.Migration

  def change do
    create table(:assessment_point_entries_evidences) do
      add :position, :integer, default: 0, null: false

      add :assessment_point_entry_id,
          references(:assessment_point_entries, on_delete: :delete_all),
          null: false

      add :attachment_id, references(:attachments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:assessment_point_entries_evidences, [:assessment_point_entry_id])

    create unique_index(:assessment_point_entries_evidences, [
             :attachment_id,
             :assessment_point_entry_id
           ])
  end
end
