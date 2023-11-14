defmodule Lanttern.Repo.Migrations.CreateClassesYears do
  use Ecto.Migration

  def change do
    create table(:classes_years, primary_key: false) do
      add :class_id, references(:classes)
      add :year_id, references(:years)
    end

    create index(:classes_years, [:class_id])
    create unique_index(:classes_years, [:year_id, :class_id])
  end
end
