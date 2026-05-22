defmodule Lanttern.Repo.Migrations.CreateStrandClassAssignments do
  use Ecto.Migration

  def change do
    create table(:strand_class_assignments) do
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :class_id, references(:classes, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:strand_class_assignments, [:strand_id, :class_id])
    create index(:strand_class_assignments, [:class_id])
  end
end
