defmodule Lanttern.Repo.Migrations.CreateGradingScales do
  use Ecto.Migration

  def change do
    create table(:grading_scales) do
      add :name, :text, null: false
      add :type, :text, null: false
      add :start, :float
      add :stop, :float

      timestamps()
    end
  end
end
