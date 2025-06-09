defmodule Lanttern.Repo.Migrations.RemoveSharedWithStudentsFromIlpComments do
  use Ecto.Migration

  def change do
    alter table(:ilp_comments) do
      remove :shared_with_students, :boolean, default: false, null: false
    end
  end
end
