defmodule Lanttern.Repo.Migrations.AddGradesReportIdToReportCards do
  use Ecto.Migration

  def change do
    alter table(:report_cards) do
      add :grades_report_id, references(:grades_reports, on_delete: :nothing)
    end

    create index(:report_cards, [:grades_report_id])
  end
end
