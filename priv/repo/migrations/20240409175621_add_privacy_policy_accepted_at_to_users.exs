defmodule Lanttern.Repo.Migrations.AddPrivacyPolicyAcceptedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :privacy_policy_accepted_at, :utc_datetime
      add :privacy_policy_accepted_meta, :text
    end
  end
end
