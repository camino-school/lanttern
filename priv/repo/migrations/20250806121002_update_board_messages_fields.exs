defmodule Lanttern.Repo.Migrations.UpdateBoardMessagesFields do
  use Ecto.Migration

  def up do
    alter table(:board_messages) do
      add :subtitle, :string
      add :color, :string
      add :cover, :string
      add :position, :integer, default: 0, null: false

      # Add section_id as nullable first
      add :section_id, references(:sections, on_delete: :delete_all), null: true
    end

    # Create a default section if it doesn't exist
    execute """
    INSERT INTO sections (name, position, inserted_at, updated_at)
    VALUES ('News', 0, NOW(), NOW())
    ON CONFLICT DO NOTHING
    """

    # Update existing messages to use the default section
    execute """
    UPDATE board_messages
    SET section_id = (SELECT id FROM sections WHERE name = 'News' LIMIT 1)
    WHERE section_id IS NULL
    """

    # Now make section_id not null
    execute "ALTER TABLE board_messages ALTER COLUMN section_id SET NOT NULL"
  end

  def down do
    alter table(:board_messages) do
      remove_if_exists :subtitle, :string
      remove_if_exists :color, :string
      remove_if_exists :cover, :string
      remove_if_exists :position, :integer
      remove_if_exists :section_id, references(:sections)
    end
  end
end
