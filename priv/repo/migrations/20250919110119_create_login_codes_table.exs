defmodule Lanttern.Repo.Migrations.CreateLoginCodesTable do
  use Ecto.Migration

  def change do
    create table(:login_codes) do
      add :email, :citext, null: false
      add :code_hash, :binary, null: false
      timestamps(updated_at: false)
    end

    create unique_index(:login_codes, [:email])
  end
end
