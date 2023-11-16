defmodule Lanttern.Repo.Migrations.LinkSubjectsAndYearsToStrands do
  use Ecto.Migration

  def change do
    create table(:strands_subjects, primary_key: false) do
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :subject_id, references(:subjects, on_delete: :delete_all), null: false
    end

    create index(:strands_subjects, [:strand_id])
    create unique_index(:strands_subjects, [:subject_id, :strand_id])

    create table(:strands_years, primary_key: false) do
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :year_id, references(:years, on_delete: :delete_all), null: false
    end

    create index(:strands_years, [:strand_id])
    create unique_index(:strands_years, [:year_id, :strand_id])
  end
end
