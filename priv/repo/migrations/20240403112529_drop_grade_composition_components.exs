defmodule Lanttern.Repo.Migrations.DropGradeCompositionComponents do
  use Ecto.Migration

  def up do
    drop table(:grade_composition_components)
  end

  def down do
    create table(:grade_composition_components) do
      add :name, :string, null: false
      add :weight, :float, null: false, default: 1.0

      add :composition_id, references(:grade_compositions, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:grade_composition_components, [:composition_id])
  end
end
