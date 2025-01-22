defmodule Lanttern.Repo.Migrations.AddStudentsSharingFieldsToMomentCards do
  use Ecto.Migration

  def change do
    alter table(:moment_cards) do
      add :shared_with_students, :boolean, default: false, null: false
      add :teacher_instructions, :text
      add :differentiation, :text
    end
  end
end
