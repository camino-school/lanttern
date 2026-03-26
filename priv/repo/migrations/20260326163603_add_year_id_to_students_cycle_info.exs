defmodule Lanttern.Repo.Migrations.AddYearIdToStudentsCycleInfo do
  use Ecto.Migration

  def change do
    alter table(:students_cycle_info) do
      add :year_id, references(:years, on_delete: :nothing)
    end

    create index(:students_cycle_info, [:year_id])
  end
end
