defmodule Lanttern.Repo.Migrations.CreateCardSections do
  use Ecto.Migration

  def change do
    create table(:card_sections) do
      add :name, :string

      timestamps()
    end
  end
end
