defmodule Lanttern.Repo.Migrations.CreateQuizItems do
  use Ecto.Migration

  def change do
    create table(:quiz_items) do
      add :position, :integer, null: false, default: 0
      add :description, :text, null: false
      add :type, :text, null: false
      add :quiz_id, references(:quizzes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:quiz_items, [:quiz_id])
  end
end
