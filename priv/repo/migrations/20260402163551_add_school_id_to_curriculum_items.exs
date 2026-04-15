defmodule Lanttern.Repo.Migrations.AddSchoolIdToCurriculumItems do
  use Ecto.Migration

  def change do
    alter table(:curriculum_items) do
      add :school_id, references(:schools, on_delete: :nothing)
    end

    create index(:curriculum_items, [:school_id])
  end
end
