defmodule Lanttern.Repo.Migrations.CreateAssessmentPointsFilterViews do
  use Ecto.Migration

  def change do
    create table(:assessment_points_filter_views) do
      add :name, :text, null: false
      add :profile_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:assessment_points_filter_views, [:profile_id])

    create table(:assessment_points_filter_views_classes, primary_key: false) do
      add :assessment_points_filter_view_id, references(:assessment_points_filter_views, on_delete: :delete_all)
      add :class_id, references(:classes, on_delete: :delete_all)
    end

    create index(:assessment_points_filter_views_classes, [:class_id])
    create unique_index(:assessment_points_filter_views_classes, [:assessment_points_filter_view_id, :class_id])

    create table(:assessment_points_filter_views_subjects, primary_key: false) do
      add :assessment_points_filter_view_id, references(:assessment_points_filter_views, on_delete: :delete_all)
      add :subject_id, references(:subjects, on_delete: :delete_all)
    end

    create index(:assessment_points_filter_views_subjects, [:subject_id])
    create unique_index(:assessment_points_filter_views_subjects, [:assessment_points_filter_view_id, :subject_id])
  end
end
