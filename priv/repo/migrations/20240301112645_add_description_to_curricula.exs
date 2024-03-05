defmodule Lanttern.Repo.Migrations.AddDescriptionToCurricula do
  use Ecto.Migration

  def change do
    alter table(:curricula) do
      add :description, :text
    end
  end
end
