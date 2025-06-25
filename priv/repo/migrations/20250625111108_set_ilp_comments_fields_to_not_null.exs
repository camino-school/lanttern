defmodule Lanttern.Repo.Migrations.SetIlpCommentsFieldsToNotNull do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE ilp_comments
            ALTER COLUMN content SET NOT NULL,
            ALTER COLUMN student_ilp_id SET NOT NULL,
            ALTER COLUMN owner_id SET NOT NULL
            """,
            """
            ALTER TABLE ilp_comments
            ALTER COLUMN content DROP NOT NULL,
            ALTER COLUMN student_ilp_id DROP NOT NULL,
            ALTER COLUMN owner_id DROP NOT NULL
            """
  end
end
