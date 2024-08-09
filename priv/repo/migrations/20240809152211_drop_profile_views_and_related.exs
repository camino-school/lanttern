defmodule Lanttern.Repo.Migrations.DropProfileViewsAndRelated do
  use Ecto.Migration

  def up do
    drop table(:profile_views_subjects)
    drop table(:profile_views_classes)
    drop table(:profile_views)
  end

  def down do
    create table(:profile_views) do
      add :name, :text, null: false
      add :profile_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:profile_views, [:profile_id])

    create table(:profile_views_classes, primary_key: false) do
      add :profile_view_id, references(:profile_views, on_delete: :delete_all)
      add :class_id, references(:classes, on_delete: :delete_all)
    end

    create index(:profile_views_classes, [:class_id])
    create unique_index(:profile_views_classes, [:profile_view_id, :class_id])

    create table(:profile_views_subjects, primary_key: false) do
      add :profile_view_id, references(:profile_views, on_delete: :delete_all)
      add :subject_id, references(:subjects, on_delete: :delete_all)
    end

    create index(:profile_views_subjects, [:subject_id])
    create unique_index(:profile_views_subjects, [:profile_view_id, :subject_id])
  end
end
