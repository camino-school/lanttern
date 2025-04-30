defmodule Lanttern.Repo.Migrations.CreateStudentRecordReportsAiConfig do
  use Ecto.Migration

  def change do
    create table(:student_record_reports_ai_config) do
      add :summary_instructions, :text
      add :update_instructions, :text
      add :model, :text
      add :cooldown_minutes, :integer, null: false, default: 0
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:student_record_reports_ai_config, [:school_id])
  end
end
