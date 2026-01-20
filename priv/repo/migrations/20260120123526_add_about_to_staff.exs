defmodule Lanttern.Repo.Migrations.AddAboutToStaff do
  use Ecto.Migration

  def change do
    alter table(:staff) do
      add :about, :text
    end
  end
end
