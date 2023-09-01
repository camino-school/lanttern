defmodule Lanttern.Repo.Migrations.AddTaxonomyToCurriculumItems do
  use Ecto.Migration

  def change do
    alter table(:curriculum_items) do
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
      add :year_id, references(:years, on_delete: :nothing), null: false
    end

    create index(:curriculum_items, [:subject_id])
    create index(:curriculum_items, [:year_id])
  end
end
