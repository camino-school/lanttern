defmodule Lanttern.Repo.Migrations.CreateStudentsInsights do
  use Ecto.Migration

  def change do
    create table(:students_insights) do
      add :description, :text, null: false
      add :author_id, references(:staff, on_delete: :nothing), null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:students_insights, [:author_id])
    create index(:students_insights, [:school_id])
    create index(:students_insights, [:inserted_at])
  end
end
