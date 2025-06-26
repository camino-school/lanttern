defmodule Lanttern.Repo.Migrations.CreateIlpCommentLogs do
  use Ecto.Migration

  @prefix "log"

  def up do
    execute("CREATE TYPE operation_type AS ENUM ('CREATE', 'UPDATE', 'DELETE')")

    create table(:ilp_comments, prefix: @prefix) do
      add :ilp_comment_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :operation_type, null: false

      add :position, :integer, null: false
      add :content, :text, null: false

      add :student_ilp_id, :bigint, null: false
      add :owner_id, :bigint, null: false

      timestamps(updated_at: false)
    end
  end

  def down do
    drop table(:ilp_comments, prefix: @prefix)
    execute "DROP TYPE IF EXISTS operation_type"
  end
end
