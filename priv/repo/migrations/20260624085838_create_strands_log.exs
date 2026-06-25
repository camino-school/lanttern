defmodule Lanttern.Repo.Migrations.CreateStrandsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:strands, prefix: @prefix) do
      add :strand_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false
      add :name, :text, null: false
      add :type, :text
      add :description, :text
      add :assessment_info, :text
      add :teacher_instructions, :text
      add :cover_image_url, :text
      add :is_locked, :boolean, null: false, default: false
      add :subjects_ids, {:array, :bigint}
      add :years_ids, {:array, :bigint}

      timestamps(updated_at: false)
    end

    create constraint(
             :strands,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )

    create index(:strands, [:strand_id], prefix: @prefix)
  end
end
