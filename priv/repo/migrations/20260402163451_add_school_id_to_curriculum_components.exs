defmodule Lanttern.Repo.Migrations.AddSchoolIdToCurriculumComponents do
  use Ecto.Migration

  def change do
    alter table(:curriculum_components) do
      add :school_id, references(:schools, on_delete: :nothing)
    end

    create index(:curriculum_components, [:school_id])
  end
end
