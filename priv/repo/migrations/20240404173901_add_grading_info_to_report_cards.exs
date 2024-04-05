defmodule Lanttern.Repo.Migrations.AddGradingInfoToReportCards do
  use Ecto.Migration

  def change do
    alter table(:report_cards) do
      add :grading_info, :text
    end
  end
end
