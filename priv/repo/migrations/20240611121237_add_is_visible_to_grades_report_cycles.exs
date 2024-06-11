defmodule Lanttern.Repo.Migrations.AddIsVisibleToGradesReportCycles do
  use Ecto.Migration

  def change do
    alter table(:grades_report_cycles) do
      add :is_visible, :boolean, null: false, default: true
    end
  end
end
