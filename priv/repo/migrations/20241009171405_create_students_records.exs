defmodule Lanttern.Repo.Migrations.CreateStudentsRecordsLogs do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:students_records, prefix: @prefix) do
      add :student_record_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false

      add :name, :text
      add :description, :text, null: false
      add :date, :date, null: false
      add :time, :time
      add :school_id, :bigint, null: false

      add :students_ids, {:array, :bigint}, null: false
      add :type_id, :bigint, null: false
      add :status_id, :bigint, null: false

      timestamps(updated_at: false)
    end

    create constraint(
             :students_records,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
