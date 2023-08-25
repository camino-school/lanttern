defmodule Lanttern.Repo.Migrations.CreateCurriculumComponents do
  use Ecto.Migration

  def change do
    create table(:curriculum_components) do
      add :name, :text, null: false
      add :code, :text
      add :curriculum_id, references(:curricula, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:curriculum_components, [:curriculum_id])
  end
end
