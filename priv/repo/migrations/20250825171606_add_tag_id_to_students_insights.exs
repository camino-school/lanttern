defmodule Lanttern.Repo.Migrations.AddTagIdToStudentsInsights do
  use Ecto.Migration

  def change do
    alter table(:students_insights) do
      add :tag_id, references(:student_insight_tags, on_delete: :nothing), null: false
    end

    create index(:students_insights, [:tag_id])
  end
end
