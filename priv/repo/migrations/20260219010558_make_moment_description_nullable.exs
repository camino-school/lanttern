defmodule Lanttern.Repo.Migrations.MakeMomentDescriptionNullable do
  use Ecto.Migration

  def change do
    alter table(:moments) do
      modify :description, :text, null: true
    end
  end
end
