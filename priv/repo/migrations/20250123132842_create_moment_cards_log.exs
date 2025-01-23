defmodule Lanttern.Repo.Migrations.CreateMomentCardsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:moment_cards, prefix: @prefix) do
      add :moment_card_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false

      add :moment_id, :bigint, null: false

      add :name, :text, null: false
      add :position, :integer, null: false
      add :description, :text, null: false
      add :teacher_instructions, :text
      add :differentiation, :text
      add :shared_with_students, :boolean, null: false

      timestamps(updated_at: false)
    end

    create constraint(
             :moment_cards,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
