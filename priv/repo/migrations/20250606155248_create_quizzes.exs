defmodule Lanttern.Repo.Migrations.CreateQuizzes do
  use Ecto.Migration

  def change do
    create table(:quizzes) do
      add :position, :integer, default: 0, null: false
      add :title, :text, null: false
      add :description, :text, null: false
      add :moment_id, references(:moments, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:quizzes, [:moment_id])
  end
end
