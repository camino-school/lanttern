defmodule Lanttern.Repo.Migrations.AddAttachmentIdToIlpCommentAttachments do
  use Ecto.Migration

  # migration strategy:
  # 1. add temporary ilp_comment_attachment_id to attachments
  # 2. insert attachments based on ilp_comment_attachments
  # 3. add attachment_id (nullable for now) and remove name/link/is_external from ilp_comment_attachments
  # 4. set attachment_id based on temp ilp_comment_attachment_id and set not null
  # 5. remove ilp_comment_attachment_id from attachments

  def up do
    alter table(:attachments) do
      add :ilp_comment_attachment_id, :bigint
    end

    execute """
            insert into attachments (
              name,
              link,
              is_external,
              owner_id,
              inserted_at,
              updated_at,
              ilp_comment_attachment_id
            )
            select
              ca.name,
              ca.link,
              ca.is_external,
              c.owner_id,
              ca.inserted_at,
              ca.updated_at,
              ca.id
            from ilp_comment_attachments ca
            join ilp_comments c on c.id = ca.ilp_comment_id
            """,
            ""

    alter table(:ilp_comment_attachments) do
      add :attachment_id, references(:attachments, on_delete: :delete_all)
      remove :name, :string
      remove :link, :string
      remove :is_external, :boolean, default: false, null: false
    end

    execute """
            update ilp_comment_attachments ca
            set attachment_id = a.id
            from attachments a
            where a.ilp_comment_attachment_id = ca.id
            """,
            ""

    execute "alter table ilp_comment_attachments alter column attachment_id set not null", ""

    alter table(:attachments) do
      remove :ilp_comment_attachment_id, :bigint
    end
  end

  def down do
    # Rollback strategy: restore original ilp_comment_attachments schema
    alter table(:attachments) do
      add :ilp_comment_attachment_id, :bigint
    end

    # Populate the temp column to identify ILP comment attachments
    execute """
            update attachments a
            set ilp_comment_attachment_id = ca.id
            from ilp_comment_attachments ca
            where ca.attachment_id = a.id
            """,
            ""

    # Restore original columns to ilp_comment_attachments
    alter table(:ilp_comment_attachments) do
      add :name, :string
      add :link, :string
      add :is_external, :boolean
    end

    # Populate restored columns from attachments data
    execute """
            update ilp_comment_attachments ca
            set 
              name = a.name,
              link = a.link,
              is_external = a.is_external
            from attachments a
            where a.id = ca.attachment_id
            """,
            ""

    # Set columns not null and remove attachment_id
    execute "alter table ilp_comment_attachments alter column name set not null", ""
    execute "alter table ilp_comment_attachments alter column link set not null", ""
    execute "alter table ilp_comment_attachments alter column is_external set not null", ""
    execute "alter table ilp_comment_attachments alter column is_external set default false", ""

    alter table(:ilp_comment_attachments) do
      remove :attachment_id, references(:attachments, on_delete: :delete_all)
    end

    # Remove attachments that were created for ILP comments using the temp column
    execute """
            delete from attachments a
            where a.ilp_comment_attachment_id is not null
            """,
            ""

    alter table(:attachments) do
      remove :ilp_comment_attachment_id, :bigint
    end
  end
end
