defmodule Lanttern.Repo.Migrations.RenameProfileViewsToProfileViews do
  use Ecto.Migration

  def up do
    # step 1: create exact same structure than assessment_points_filter_views

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

    # step 2: copy assessment point filter views to profile views

    execute """
    INSERT INTO profile_views
    SELECT * FROM assessment_points_filter_views
    """

    execute """
    SELECT setval(
      'profile_views_id_seq',
      (SELECT id FROM profile_views ORDER BY id DESC LIMIT 1),
      true
    )
    """

    execute """
    INSERT INTO profile_views_subjects
    SELECT * FROM assessment_points_filter_views_subjects
    """

    execute """
    INSERT INTO profile_views_classes
    SELECT * FROM assessment_points_filter_views_classes
    """

    # step 3: drop assessment points filter views tables

    drop table(:assessment_points_filter_views_subjects)
    drop table(:assessment_points_filter_views_classes)
    drop table(:assessment_points_filter_views)
  end

  def down do
    # step 1: re-create assessment_points_filter_views

    create table(:assessment_points_filter_views) do
      add :name, :text, null: false
      add :profile_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:assessment_points_filter_views, [:profile_id])

    create table(:assessment_points_filter_views_classes, primary_key: false) do
      add :assessment_points_filter_view_id,
          references(:assessment_points_filter_views, on_delete: :delete_all)

      add :class_id, references(:classes, on_delete: :delete_all)
    end

    create index(:assessment_points_filter_views_classes, [:class_id])

    create unique_index(:assessment_points_filter_views_classes, [
             :assessment_points_filter_view_id,
             :class_id
           ])

    create table(:assessment_points_filter_views_subjects, primary_key: false) do
      add :assessment_points_filter_view_id,
          references(:assessment_points_filter_views, on_delete: :delete_all)

      add :subject_id, references(:subjects, on_delete: :delete_all)
    end

    create index(:assessment_points_filter_views_subjects, [:subject_id])

    create unique_index(:assessment_points_filter_views_subjects, [
             :assessment_points_filter_view_id,
             :subject_id
           ])

    # step 2: copy back assessment point filter views from profile views

    execute """
    INSERT INTO assessment_points_filter_views
    SELECT * FROM profile_views
    """

    execute """
    SELECT setval(
      'assessment_points_filter_views_id_seq',
      (SELECT id FROM profile_views ORDER BY id DESC LIMIT 1),
      true
    )
    """

    execute """
    INSERT INTO assessment_points_filter_views_subjects
    SELECT * FROM profile_views_subjects
    """

    execute """
    INSERT INTO assessment_points_filter_views_classes
    SELECT * FROM profile_views_classes
    """

    # step 3: drop profile views tables

    drop table(:profile_views_subjects)
    drop table(:profile_views_classes)
    drop table(:profile_views)
  end
end
