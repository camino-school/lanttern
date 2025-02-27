defmodule Lanttern.Repo.Migrations.CreateStudentsIlpsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:students_ilps, prefix: @prefix) do
      add :student_ilp_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false

      add :teacher_notes, :text

      add :template_id, :bigint, null: false
      add :student_id, :bigint, null: false
      add :cycle_id, :bigint, null: false
      add :school_id, :bigint, null: false
      add :update_of_ilp_id, :bigint

      add :entries, :map

      timestamps(updated_at: false)
    end

    create constraint(
             :students_ilps,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
