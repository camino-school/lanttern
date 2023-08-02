defmodule Lanttern.Repo.Migrations.CreateNumericScales do
  use Ecto.Migration

  def change do
    create table(:numeric_scales) do
      add :name, :text, null: false
      add :start, :float, null: false
      add :stop, :float, null: false

      timestamps()
    end
  end
end
