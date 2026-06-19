defmodule Lanttern.Repo.Migrations.ReplaceStudentGuardianAccessWithAllowAccess do
  use Ecto.Migration

  def up do
    alter table(:student_report_cards) do
      add :allow_access, :boolean, null: false, default: false
    end

    flush()

    execute "UPDATE student_report_cards SET allow_access = (allow_student_access OR allow_guardian_access)"

    alter table(:student_report_cards) do
      remove :allow_student_access
      remove :allow_guardian_access
    end
  end

  def down do
    alter table(:student_report_cards) do
      add :allow_student_access, :boolean, null: false, default: false
      add :allow_guardian_access, :boolean, null: false, default: false
    end

    flush()

    execute "UPDATE student_report_cards SET allow_student_access = allow_access, allow_guardian_access = allow_access"

    alter table(:student_report_cards) do
      remove :allow_access
    end
  end
end
