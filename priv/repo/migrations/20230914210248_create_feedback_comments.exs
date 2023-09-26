defmodule Lanttern.Repo.Migrations.CreateFeedbackComments do
  use Ecto.Migration

  def change do
    create table(:feedback_comments, primary_key: false) do
      add :feedback_id, references(:feedback), null: false
      add :comment_id, references(:comments), null: false
    end

    create index(:feedback_comments, [:feedback_id])
    create unique_index(:feedback_comments, [:comment_id])
  end
end
