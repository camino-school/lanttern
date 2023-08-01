defmodule Lanttern.Repo.Migrations.CreateOrdinalValues do
  use Ecto.Migration

  def change do
    create table(:ordinal_values) do
      add :name, :text, null: false
      add :order, :integer, null: false
      add :scale_id, references(:ordinal_scales, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ordinal_values, [:scale_id])
  end
end
