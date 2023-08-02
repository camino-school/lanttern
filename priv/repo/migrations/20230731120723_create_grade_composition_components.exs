defmodule Lanttern.Repo.Migrations.CreateGradeCompositionComponents do
  use Ecto.Migration

  def change do
    create table(:grade_composition_components) do
      add :name, :string, null: false
      add :weight, :float, null: false, default: 1.0

      add :composition_id, references(:grade_compositions, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:grade_composition_components, [:composition_id])
  end
end
