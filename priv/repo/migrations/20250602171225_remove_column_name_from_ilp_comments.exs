defmodule Lanttern.Repo.Migrations.RemoveColumnNameFromIlpComments do
  use Ecto.Migration

  def change do
    alter table(:ilp_comments) do
      remove :name
    end
  end
end
