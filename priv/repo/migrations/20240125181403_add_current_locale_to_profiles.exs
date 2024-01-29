defmodule Lanttern.Repo.Migrations.AddCurrentLocaleToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :current_locale, :string, null: false, default: "en"
    end
  end
end
