defmodule Lanttern.Repo.Migrations.CreateAnalyticsStrandReportViews do
  use Ecto.Migration

  @prefix "analytics"

  def change do
    create table(:strand_report_views, prefix: @prefix) do
      add :profile_id, :bigint, null: false
      add :strand_report_id, :bigint, null: false
      add :student_report_card_id, :bigint
      add :navigation_context, :text, null: false
      add :tab, :text, null: false
      add :date, :date, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:strand_report_views, [:profile_id, :strand_report_id, :tab, :date],
             prefix: @prefix
           )

    create index(:strand_report_views, [:strand_report_id], prefix: @prefix)

    create constraint(:strand_report_views, :navigation_context_check,
             check: "navigation_context IN ('strand_report', 'report_card')",
             prefix: @prefix
           )

    create constraint(:strand_report_views, :tab_check,
             check: "tab IN ('overview', 'rubrics', 'assessment', 'ongoing_assessment')",
             prefix: @prefix
           )
  end
end
