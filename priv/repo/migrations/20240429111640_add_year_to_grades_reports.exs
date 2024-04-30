defmodule Lanttern.Repo.Migrations.AddYearToGradesReports do
  use Ecto.Migration

  def change do
    alter table(:grades_reports) do
      # we need to set null: false later, after handling the "migration" in production
      add :year_id, references(:years, on_delete: :nothing)
    end

    create unique_index(:grades_reports, [:year_id, :school_cycle_id])
  end
end
