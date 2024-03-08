defmodule Lanttern.Repo.Migrations.AdjustGradeReports do
  use Ecto.Migration

  def change do
    # "clear" table before migrating
    execute "DELETE FROM grade_reports", ""

    alter table(:grade_reports) do
      remove :subject_id, references(:subjects, on_delete: :nothing), null: false
      remove :year_id, references(:years, on_delete: :nothing), null: false

      add :name, :text, null: false
    end
  end
end
