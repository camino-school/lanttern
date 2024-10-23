defmodule Lanttern.Repo.Migrations.AddShortNameToSubjects do
  use Ecto.Migration

  def change do
    alter table(:subjects) do
      add :short_name, :text
    end
  end
end
