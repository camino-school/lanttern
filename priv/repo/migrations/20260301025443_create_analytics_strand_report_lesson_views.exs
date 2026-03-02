defmodule Lanttern.Repo.Migrations.CreateAnalyticsStrandReportLessonViews do
  use Ecto.Migration

  @prefix "analytics"

  def change do
    create table(:strand_report_lesson_views, prefix: @prefix) do
      add :profile_id, :bigint, null: false
      add :strand_report_id, :bigint, null: false
      add :lesson_id, :bigint, null: false
      add :student_report_card_id, :bigint
      add :date, :date, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:strand_report_lesson_views, [:profile_id, :lesson_id, :date],
             prefix: @prefix
           )

    create index(:strand_report_lesson_views, [:lesson_id], prefix: @prefix)
  end
end
