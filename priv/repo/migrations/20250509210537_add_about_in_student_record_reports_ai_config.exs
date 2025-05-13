defmodule Lanttern.Repo.Migrations.AddAboutInStudentRecordReportsAiConfig do
  use Ecto.Migration

  def change do
    alter table(:student_record_reports_ai_config) do
      add :about, :text
    end
  end
end
