defmodule Lanttern.Repo.Migrations.DropFeedbackAndCommentsTables do
  use Ecto.Migration

  def change do
    drop table(:feedback_comments)
    drop table(:feedback)
    drop table(:comments)
  end
end
