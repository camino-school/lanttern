defmodule Lanttern.Repo.Migrations.CreateStudentInsightTags do
  use Ecto.Migration

  def change do
    create table(:student_insight_tags) do
      add :name, :string, null: false
      add :text_color, :string
      add :bg_color, :string
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:student_insight_tags, [:school_id])
  end
end
