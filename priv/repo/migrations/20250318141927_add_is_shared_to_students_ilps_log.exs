defmodule Lanttern.Repo.Migrations.AddIsSharedToStudentsIlpsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:students_ilps, prefix: @prefix) do
      add :is_shared_with_student, :boolean, default: false
      add :is_shared_with_guardians, :boolean, default: false
    end
  end
end
