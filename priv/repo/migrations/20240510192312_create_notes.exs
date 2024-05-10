defmodule Lanttern.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:notes, prefix: @prefix) do
      add :note_id, :bigint, null: false
      add :author_id, :bigint, null: false
      add :description, :text, null: false
      add :operation, :text, null: false
      add :type, :text
      add :type_id, :bigint

      timestamps(updated_at: false)
    end

    create constraint(
             :notes,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
