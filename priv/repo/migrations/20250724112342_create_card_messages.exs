defmodule Lanttern.Repo.Migrations.CreateCardMessages do
  use Ecto.Migration

  def change do
    create table(:card_messages) do
      add :title, :string
      add :subtitle, :string
      add :content, :text
      add :color, :string
      add :cover, :string

      add :card_section_id, references(:card_sections, on_delete: :delete_all)

      timestamps()
    end

    create index(:card_messages, [:card_section_id])
  end
end
