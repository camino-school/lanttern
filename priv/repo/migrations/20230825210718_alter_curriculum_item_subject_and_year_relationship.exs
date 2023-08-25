defmodule Lanttern.Repo.Migrations.AlterCurriculumItemSubjectAndYearRelationship do
  use Ecto.Migration

  def change do
    drop index(:curriculum_items, [:subject_id])
    drop index(:curriculum_items, [:year_id])

    alter table(:curriculum_items) do
      remove :subject_id, references(:subjects, on_delete: :nothing), null: false
      remove :year_id, references(:years, on_delete: :nothing), null: false
    end

    create table(:curriculum_items_subjects, primary_key: false) do
      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing), null: false
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
    end

    create index(:curriculum_items_subjects, [:curriculum_item_id])
    create index(:curriculum_items_subjects, [:subject_id])
    create unique_index(:curriculum_items_subjects, [:curriculum_item_id, :subject_id])

    create table(:curriculum_items_years, primary_key: false) do
      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing), null: false
      add :year_id, references(:years, on_delete: :nothing), null: false
    end

    create index(:curriculum_items_years, [:curriculum_item_id])
    create index(:curriculum_items_years, [:year_id])
    create unique_index(:curriculum_items_years, [:curriculum_item_id, :year_id])
  end
end
