defmodule Lanttern.Repo.Migrations.AddLockProvenanceToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :locked_at, :utc_datetime
      add :locked_by_staff_member_id, references(:staff, on_delete: :nothing)
    end

    create index(:strands, [:locked_by_staff_member_id])
  end
end
