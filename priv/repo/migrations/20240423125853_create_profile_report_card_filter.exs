defmodule Lanttern.Repo.Migrations.CreateProfileReportCardFilter do
  use Ecto.Migration

  def change do
    create table(:profile_report_card_filters) do
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
      add :report_card_id, references(:report_cards, on_delete: :delete_all), null: false
      add :class_id, references(:classes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:profile_report_card_filters, [:profile_id])
    create index(:profile_report_card_filters, [:report_card_id])
    create unique_index(:profile_report_card_filters, [:class_id, :profile_id, :report_card_id])
  end
end
