defmodule Lanttern.Repo.Migrations.AddUniqueNameSchoolConstraintToStudentsAndTeachers do
  use Ecto.Migration

  def change do
    create unique_index(:students, [:name, :school_id])
    create unique_index(:teachers, [:name, :school_id])
  end
end
