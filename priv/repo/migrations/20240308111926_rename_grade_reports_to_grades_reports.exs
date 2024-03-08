defmodule Lanttern.Repo.Migrations.RenameGradeReportsToGradesReports do
  use Ecto.Migration

  def change do
    # grade_reports to gradeS_reports

    # table
    execute "ALTER TABLE grade_reports RENAME TO grades_reports",
            "ALTER TABLE grades_reports RENAME TO grade_reports"

    # indexes
    execute "ALTER INDEX grade_reports_pkey RENAME TO grades_reports_pkey",
            "ALTER INDEX grades_reports_pkey RENAME TO grade_reports_pkey"

    execute "ALTER INDEX grade_reports_scale_id_index RENAME TO grades_reports_scale_id_index",
            "ALTER INDEX grades_reports_scale_id_index RENAME TO grade_reports_scale_id_index"

    execute "ALTER INDEX grade_reports_school_cycle_id_index RENAME TO grades_reports_school_cycle_id_index",
            "ALTER INDEX grades_reports_school_cycle_id_index RENAME TO grade_reports_school_cycle_id_index"

    # constraints
    execute "ALTER TABLE grades_reports RENAME CONSTRAINT grade_reports_scale_id_fkey TO grades_reports_scale_id_fkey",
            "ALTER TABLE grades_reports RENAME CONSTRAINT grades_reports_scale_id_fkey TO grade_reports_scale_id_fkey"

    execute "ALTER TABLE grades_reports RENAME CONSTRAINT grade_reports_school_cycle_id_fkey TO grades_reports_school_cycle_id_fkey",
            "ALTER TABLE grades_reports RENAME CONSTRAINT grades_reports_school_cycle_id_fkey TO grade_reports_school_cycle_id_fkey"
  end
end
