defmodule Lanttern.Repo.Migrations.CreateConversionRules do
  use Ecto.Migration

  def change do
    create table(:conversion_rules) do
      add :name, :text, null: false
      add :conversions, :map
      add :from_scale_id, references(:grading_scales, on_delete: :delete_all), null: false
      add :to_scale_id, references(:grading_scales, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:conversion_rules, [:from_scale_id])
    create index(:conversion_rules, [:to_scale_id])
    create unique_index(:conversion_rules, [:from_scale_id, :to_scale_id])

    create constraint(
             :conversion_rules,
             :from_and_to_scales_should_be_different,
             check: "from_scale_id <> to_scale_id"
           )
  end
end
