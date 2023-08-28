defmodule Lanttern.Repo.Migrations.AddCodeColumnsToSubjectsAndYears do
  use Ecto.Migration

  def change do
    alter table(:subjects) do
      add :code, :text
    end

    create unique_index(:subjects, [:code])

    alter table(:years) do
      add :code, :text
    end

    create unique_index(:years, [:code])
  end
end
