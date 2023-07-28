defmodule Lanttern.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students) do
      add :name, :text

      timestamps()
    end
  end
end
