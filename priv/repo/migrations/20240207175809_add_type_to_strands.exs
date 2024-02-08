defmodule Lanttern.Repo.Migrations.AddTypeToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :type, :text
    end
  end
end
