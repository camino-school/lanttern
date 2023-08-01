defmodule Lanttern.Repo.Migrations.DropOrdinalAndNumericScales do
  use Ecto.Migration

  def up do
    # we are dropping ordinal_values to "clean" to avoid conflicts in the scale_id column
    drop table(:ordinal_values)

    drop table(:ordinal_scales)
    drop table(:numeric_scales)

    create table(:ordinal_values) do
      add :name, :text, null: false
      add :order, :integer, null: false
      add :scale_id, references(:grading_scales, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ordinal_values, [:scale_id])
  end

  def down do
    drop table(:ordinal_values)

    create table(:numeric_scales) do
      add :name, :text, null: false
      add :start, :float, null: false
      add :stop, :float, null: false

      timestamps()
    end

    create table(:ordinal_scales) do
      add :name, :text, null: false

      timestamps()
    end

    create table(:ordinal_values) do
      add :name, :text, null: false
      add :order, :integer, null: false
      add :scale_id, references(:ordinal_scales, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ordinal_values, [:scale_id])
  end
end
