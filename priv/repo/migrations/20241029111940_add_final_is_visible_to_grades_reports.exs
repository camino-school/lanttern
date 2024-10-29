defmodule Lanttern.Repo.Migrations.AddFinalIsVisibleToGradesReports do
  use Ecto.Migration

  def change do
    alter table(:grades_reports) do
      add :final_is_visible, :boolean, null: false, default: false
    end
  end
end
