defmodule Lanttern.Repo.Migrations.AddLegacyCommentsToNotesTables do
  use Ecto.Migration

  def up do
    execute(
      "COMMENT ON TABLE notes IS 'Legacy — notes feature removed in v1 transition. See docs/legacy.md.'"
    )

    execute(
      "COMMENT ON TABLE strands_notes IS 'Legacy — notes feature removed in v1 transition. See docs/legacy.md.'"
    )

    execute(
      "COMMENT ON TABLE moments_notes IS 'Legacy — notes feature removed in v1 transition. See docs/legacy.md.'"
    )

    execute(
      "COMMENT ON TABLE notes_attachments IS 'Legacy — notes feature removed in v1 transition. See docs/legacy.md.'"
    )

    execute(
      "COMMENT ON TABLE log.notes IS 'Legacy — notes audit log, notes feature removed in v1 transition. See docs/legacy.md.'"
    )
  end

  def down do
    execute("COMMENT ON TABLE notes IS NULL")
    execute("COMMENT ON TABLE strands_notes IS NULL")
    execute("COMMENT ON TABLE moments_notes IS NULL")
    execute("COMMENT ON TABLE notes_attachments IS NULL")
    execute("COMMENT ON TABLE log.notes IS NULL")
  end
end
