defmodule Lanttern.Repo.Migrations.AddShortNameToOrdinalValues do
  use Ecto.Migration

  def change do
    alter table(:ordinal_values) do
      add :short_name, :string
    end
  end
end
