defmodule Lanttern.Repo.Migrations.AddCoverImageUrlToReportCards do
  use Ecto.Migration

  def change do
    alter table(:report_cards) do
      add :cover_image_url, :text
    end

    alter table(:student_report_cards) do
      add :cover_image_url, :text
    end

    alter table(:strand_reports) do
      add :cover_image_url, :text
    end
  end
end
