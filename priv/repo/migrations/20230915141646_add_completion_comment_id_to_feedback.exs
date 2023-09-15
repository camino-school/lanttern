defmodule Lanttern.Repo.Migrations.AddCompletionCommentIdToFeedback do
  use Ecto.Migration

  def change do
    alter table(:feedback) do
      add :completion_comment_id, references(:comments, on_delete: :nothing)
    end

    create unique_index(:feedback, [:completion_comment_id])
  end
end
