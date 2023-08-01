defmodule Lanttern.Repo.Migrations.CreateOrdinalScales do
  use Ecto.Migration

  def change do
    create table(:ordinal_scales) do
      add :name, :text, null: false

      timestamps()
    end
  end
end
