defmodule Lanttern.Repo.Migrations.CreateIlpTemplates do
  use Ecto.Migration

  def change do
    create table(:ilp_templates) do
      add :name, :text, null: false
      add :description, :text
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    # create as unique index with id to allow composite foreign keys
    create unique_index(:ilp_templates, [:school_id, :id])
  end
end
