defmodule Lanttern.Repo.Migrations.CreateMomentCardsAttachments do
  use Ecto.Migration

  def change do
    create table(:moment_cards_attachments) do
      add :position, :integer, default: 0, null: false
      add :share_with_family, :boolean, default: false, null: false
      add :moment_card_id, references(:moment_cards, on_delete: :delete_all), null: false
      add :attachment_id, references(:attachments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:moment_cards_attachments, [:moment_card_id])
    create unique_index(:moment_cards_attachments, [:attachment_id, :moment_card_id])
    create index(:moment_cards_attachments, [:position])
  end
end
