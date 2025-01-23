defmodule Lanttern.Repo.Migrations.AlterMomentCardAttachmentSharedWithFamily do
  use Ecto.Migration

  def change do
    rename table(:moment_cards_attachments), :share_with_family, to: :shared_with_students
  end
end
