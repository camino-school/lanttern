defmodule Lanttern.Repo.Migrations.CreateIlpCommentAttachments do
  use Ecto.Migration

  def change do
    create table(:ilp_comment_attachments) do
      add :name, :string
      add :link, :string
      add :position, :integer, default: 0, null: false
      add :shared_with_students, :boolean, default: false, null: false
      add :is_external, :boolean, default: false, null: false
      add :ilp_comment_id, references(:ilp_comments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ilp_comment_attachments, [:ilp_comment_id])
  end
end
