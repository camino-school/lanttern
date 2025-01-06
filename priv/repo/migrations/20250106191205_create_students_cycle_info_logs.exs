defmodule Lanttern.Repo.Migrations.CreateStudentsCycleInfoLogs do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:students_cycle_info, prefix: @prefix) do
      add :student_cycle_info_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false

      add :student_id, :bigint, null: false
      add :cycle_id, :bigint, null: false
      add :school_id, :bigint, null: false

      add :school_info, :text
      add :family_info, :text
      add :profile_picture_url, :text

      timestamps(updated_at: false)
    end

    create constraint(
             :students_cycle_info,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
