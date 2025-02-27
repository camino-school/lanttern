defmodule Lanttern.Repo.Migrations.AddNotesToStudentsIlps do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:students_ilps) do
      add :notes, :text
    end

    alter table(:students_ilps, prefix: @prefix) do
      add :notes, :text
    end
  end
end
