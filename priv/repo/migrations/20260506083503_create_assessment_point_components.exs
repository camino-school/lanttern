defmodule Lanttern.Repo.Migrations.CreateAssessmentPointComponents do
  use Ecto.Migration

  def change do
    create table(:assessment_point_components) do
      add :weight, :float, default: 1.0, null: false
      add :parent_id, references(:assessment_points, on_delete: :delete_all), null: false
      add :component_id, references(:assessment_points, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:assessment_point_components, [:component_id])
    create unique_index(:assessment_point_components, [:parent_id, :component_id])

    create constraint(:assessment_point_components, :parent_and_component_must_differ,
             check: "parent_id != component_id"
           )
  end
end
