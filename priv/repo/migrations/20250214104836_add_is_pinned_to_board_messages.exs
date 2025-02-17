defmodule Lanttern.Repo.Migrations.AddIsPinnedToBoardMessages do
  use Ecto.Migration

  def change do
    alter table(:board_messages) do
      add :is_pinned, :boolean, default: false, null: false
    end
  end
end
