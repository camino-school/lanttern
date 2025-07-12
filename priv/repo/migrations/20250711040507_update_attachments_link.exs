defmodule Lanttern.Repo.Migrations.UpdateAttachmentsLink do
  use Ecto.Migration

  def change do
    execute """
      UPDATE attachments
      SET link = regexp_replace(link, '^.*/attachments/', '')
    """
  end
end
