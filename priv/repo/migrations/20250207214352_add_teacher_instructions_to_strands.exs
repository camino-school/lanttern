defmodule Lanttern.Repo.Migrations.AddTeacherInstructionsToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :teacher_instructions, :text
    end
  end
end
