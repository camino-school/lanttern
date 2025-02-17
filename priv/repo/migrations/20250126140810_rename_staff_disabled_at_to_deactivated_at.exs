defmodule Lanttern.Repo.Migrations.RenameStaffDisabledAtToDeactivatedAt do
  use Ecto.Migration

  def change do
    rename table(:staff), :disabled_at, to: :deactivated_at
  end
end
