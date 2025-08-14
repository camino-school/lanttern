defmodule Lanttern.Repo.Migrations.UpdateBoardMessagesFields do
  use Ecto.Migration

  def up do
    alter table(:board_messages) do
      add :subtitle, :string
      add :color, :string
      add :cover, :string
      add :position, :integer, default: 0, null: false

      add :section_id, references(:sections, on_delete: :delete_all), null: false
    end
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
