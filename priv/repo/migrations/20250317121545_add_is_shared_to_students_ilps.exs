defmodule Lanttern.Repo.Migrations.AddIsSharedToStudentsIlps do
  use Ecto.Migration

  def change do
    alter table(:students_ilps) do
      add :is_shared_with_student, :boolean, default: false
      add :is_shared_with_guardians, :boolean, default: false
    end
  end
end
