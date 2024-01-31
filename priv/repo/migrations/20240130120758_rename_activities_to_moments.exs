defmodule Lanttern.Repo.Migrations.RenameActivitiesToMoments do
  use Ecto.Migration

  def change do
    # activities to moments

    # table
    execute "ALTER TABLE activities RENAME TO moments",
            "ALTER TABLE moments RENAME TO activities"

    # indexes
    execute "ALTER INDEX activities_pkey RENAME TO moments_pkey",
            "ALTER INDEX moments_pkey RENAME TO activities_pkey"

    execute "ALTER INDEX activities_strand_id_index RENAME TO moments_strand_id_index",
            "ALTER INDEX moments_strand_id_index RENAME TO activities_strand_id_index"

    # constraints
    execute "ALTER TABLE moments RENAME CONSTRAINT activities_strand_id_fkey TO moments_strand_id_fkey",
            "ALTER TABLE moments RENAME CONSTRAINT moments_strand_id_fkey TO activities_strand_id_fkey"

    # activities_notes to moments_notes

    # table and columns
    execute "ALTER TABLE activities_notes RENAME TO moments_notes",
            "ALTER TABLE moments_notes RENAME TO activities_notes"

    execute "ALTER TABLE moments_notes RENAME COLUMN activity_id TO moment_id",
            "ALTER TABLE moments_notes RENAME COLUMN moment_id TO activity_id"

    # indexes
    execute "ALTER INDEX activities_notes_activity_id_index RENAME TO moments_notes_moment_id_index",
            "ALTER INDEX moments_notes_moment_id_index RENAME TO activities_notes_activity_id_index"

    execute "ALTER INDEX activities_notes_author_id_activity_id_index RENAME TO moments_notes_author_id_moment_id_index",
            "ALTER INDEX moments_notes_author_id_moment_id_index RENAME TO activities_notes_author_id_activity_id_index"

    execute "ALTER INDEX activities_notes_note_id_index RENAME TO moments_notes_note_id_index",
            "ALTER INDEX moments_notes_note_id_index RENAME TO activities_notes_note_id_index"

    # constraints
    execute "ALTER TABLE moments_notes RENAME CONSTRAINT activities_notes_activity_id_fkey TO moments_notes_moment_id_fkey",
            "ALTER TABLE moments_notes RENAME CONSTRAINT moments_notes_moment_id_fkey TO activities_notes_activity_id_fkey"

    execute "ALTER TABLE moments_notes RENAME CONSTRAINT activities_notes_author_id_fkey TO moments_notes_author_id_fkey",
            "ALTER TABLE moments_notes RENAME CONSTRAINT moments_notes_author_id_fkey TO activities_notes_author_id_fkey"

    execute "ALTER TABLE moments_notes RENAME CONSTRAINT activities_notes_note_id_fkey TO moments_notes_note_id_fkey",
            "ALTER TABLE moments_notes RENAME CONSTRAINT moments_notes_note_id_fkey TO activities_notes_note_id_fkey"

    # activities_subjects to moments_subjects

    # table and columns
    execute "ALTER TABLE activities_subjects RENAME TO moments_subjects",
            "ALTER TABLE moments_subjects RENAME TO activities_subjects"

    execute "ALTER TABLE moments_subjects RENAME COLUMN activity_id TO moment_id",
            "ALTER TABLE moments_subjects RENAME COLUMN moment_id TO activity_id"

    # indexes
    execute "ALTER INDEX activities_subjects_activity_id_index RENAME TO moments_subjects_moment_id_index",
            "ALTER INDEX moments_subjects_moment_id_index RENAME TO activities_subjects_activity_id_index"

    execute "ALTER INDEX activities_subjects_subject_id_activity_id_index RENAME TO moments_subjects_subject_id_moment_id_index",
            "ALTER INDEX moments_subjects_subject_id_moment_id_index RENAME TO activities_subjects_subject_id_activity_id_index"

    # constraints
    execute "ALTER TABLE moments_subjects RENAME CONSTRAINT activities_subjects_activity_id_fkey TO moments_subjects_moment_id_fkey",
            "ALTER TABLE moments_subjects RENAME CONSTRAINT moments_subjects_moment_id_fkey TO activities_subjects_activity_id_fkey"

    execute "ALTER TABLE moments_subjects RENAME CONSTRAINT activities_subjects_subject_id_fkey TO moments_subjects_subject_id_fkey",
            "ALTER TABLE moments_subjects RENAME CONSTRAINT moments_subjects_subject_id_fkey TO activities_subjects_subject_id_fkey"

    # assessment points

    # column
    execute "ALTER TABLE assessment_points RENAME COLUMN activity_id TO moment_id",
            "ALTER TABLE assessment_points RENAME COLUMN moment_id TO activity_id"

    # indexes
    execute "ALTER INDEX assessment_points_activity_id_index RENAME TO assessment_points_moment_id_index",
            "ALTER INDEX assessment_points_moment_id_index RENAME TO assessment_points_activity_id_index"

    # constraints
    execute "ALTER TABLE assessment_points RENAME CONSTRAINT assessment_points_activity_id_fkey TO assessment_points_moment_id_fkey",
            "ALTER TABLE assessment_points RENAME CONSTRAINT assessment_points_moment_id_fkey TO assessment_points_activity_id_fkey"
  end
end
