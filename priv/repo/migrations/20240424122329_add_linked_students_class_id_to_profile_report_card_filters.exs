defmodule Lanttern.Repo.Migrations.AddLinkedStudentsClassIdToProfileReportCardFilters do
  use Ecto.Migration

  # MIGRATION PLAN
  # 1. remove not null constraint from class_id
  # 2. add column linked_students_class_id (references classes)
  # 4. add unique constraint to prevent duplicate linked_students_class_id per report/profile
  # 4. add check constraint: class_id is not null and linked_students_class_id is null (or vice-versa)

  def change do
    execute "ALTER TABLE profile_report_card_filters ALTER COLUMN class_id DROP NOT NULL",
            "ALTER TABLE profile_report_card_filters ALTER COLUMN class_id SET NOT NULL"

    alter table(:profile_report_card_filters) do
      add :linked_students_class_id, references(:classes, on_delete: :delete_all)
    end

    create unique_index(:profile_report_card_filters, [
             :linked_students_class_id,
             :profile_id,
             :report_card_id
           ])

    check_constraint = """
    (class_id IS NOT NULL AND linked_students_class_id IS NULL)
    OR (class_id IS NULL AND linked_students_class_id IS NOT NULL)
    """

    create constraint(
             :profile_report_card_filters,
             :required_filter_value,
             check: check_constraint
           )
  end
end
