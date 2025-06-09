defmodule Lanttern.Repo.Migrations.RemoveSharedWithStudentsFromIlpCommentAttachments do
  use Ecto.Migration

  def change do
    alter table(:ilp_comment_attachments) do
      remove :shared_with_students, :boolean, default: false, null: false
    end
  end
end
