defmodule Lanttern.Repo.Migrations.CreateQuizItemAlternatives do
  use Ecto.Migration

  def change do
    create table(:quiz_item_alternatives) do
      add :position, :integer, default: 0, null: false
      add :description, :text, null: false
      add :is_correct, :boolean, default: false, null: false
      add :quiz_item_id, references(:quiz_items, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:quiz_item_alternatives, [:quiz_item_id])

    create unique_index(:quiz_item_alternatives, [:is_correct, :quiz_item_id],
             where: "is_correct IS TRUE"
           )
  end
end
