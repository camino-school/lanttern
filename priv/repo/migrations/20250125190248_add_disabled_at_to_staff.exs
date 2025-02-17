defmodule Lanttern.Repo.Migrations.AddDisabledAtToStaff do
  use Ecto.Migration

  def change do
    alter table(:staff) do
      add :disabled_at, :utc_datetime
    end
  end
end
