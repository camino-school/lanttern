defmodule Lanttern.Repo.Migrations.RemoveSendToConstraintFromMessages do
  use Ecto.Migration

  def change do
    drop constraint(:messages, :valid_send_to)
  end
end
