defmodule Lanttern.Repo.Migrations.CreateActivitiesCurriculumItems do
  use Ecto.Migration

  def change do
    create table(:activities_curriculum_items) do
      add :position, :integer, null: false, default: 0
      add :activity_id, references(:activities, on_delete: :delete_all), null: false
      add :curriculum_item_id, references(:curriculum_items, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:activities_curriculum_items, [:activity_id])
    create unique_index(:activities_curriculum_items, [:curriculum_item_id, :activity_id])
  end
end
