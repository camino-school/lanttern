defmodule Lanttern.Repo.Migrations.CreateLessonTags do
  use Ecto.Migration

  def change do
    create table(:lesson_tags) do
      add :name, :string, null: false
      add :agent_description, :text
      add :bg_color, :string, null: false
      add :text_color, :string, null: false
      add :position, :integer, default: 0, null: false
      add :school_id, references(:schools, type: :id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:lesson_tags, [:position])
    create unique_index(:lesson_tags, [:school_id, :id])

    create constraint(
             :lesson_tags,
             :lesson_tags_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :lesson_tags,
             :lesson_tags_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
