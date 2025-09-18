defmodule Lanttern.Repo.Migrations.AddAuthenticatedAtToUsersTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :authenticated_at, :utc_datetime
    end
  end
end
