defmodule Lanttern.Repo.Migrations.UpdateBoardMessagesFields do
  use Ecto.Migration

  def change do
    alter table(:board_messages) do
      add :subtitle, :string
      add :color, :string
      add :cover, :string
      add :section, :string
    end
  end
end
