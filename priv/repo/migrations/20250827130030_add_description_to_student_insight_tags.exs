defmodule Lanttern.Repo.Migrations.AddDescriptionToStudentInsightTags do
  use Ecto.Migration

  def change do
    alter table(:student_insight_tags) do
      add :description, :text
    end
  end
end
