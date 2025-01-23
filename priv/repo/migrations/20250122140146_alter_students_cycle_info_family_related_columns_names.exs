defmodule Lanttern.Repo.Migrations.AlterStudentsCycleInfoFamilyRelatedColumnsNames do
  use Ecto.Migration

  @prefix "log"

  def change do
    rename table(:students_cycle_info), :family_info, to: :shared_info
    rename table(:students_cycle_info, prefix: @prefix), :family_info, to: :shared_info
    rename table(:students_cycle_info_attachments), :is_family, to: :shared_with_student
  end
end
