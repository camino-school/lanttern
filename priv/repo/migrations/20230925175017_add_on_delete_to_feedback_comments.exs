defmodule Lanttern.Repo.Migrations.AddOnDeleteToFeedbackComments do
  use Ecto.Migration

  def change do
    # adjust constraints in feedback_comments table
    alter table(:feedback_comments) do
      modify :feedback_id, references(:feedback, on_delete: :delete_all),
        from: references(:feedback)

      modify :comment_id, references(:comments, on_delete: :delete_all),
        from: references(:comments)
    end

    # adjust constraints in feedback table
    alter table(:feedback) do
      modify :completion_comment_id, references(:comments, on_delete: :nilify_all),
        from: references(:comments, on_delete: :nothing)
    end
  end
end
