defmodule Lanttern.Repo.Migrations.AddVisibilityControlToStudentReportCards do
  use Ecto.Migration

  def change do
    alter table(:student_report_cards) do
      add :allow_student_access, :boolean, null: false, default: false
      add :allow_guardian_access, :boolean, null: false, default: false
    end

    # execute a query to set access to true on migration for existing reports
    execute "UPDATE student_report_cards SET allow_student_access = TRUE", ""
    execute "UPDATE student_report_cards SET allow_guardian_access = TRUE", ""
  end
end
