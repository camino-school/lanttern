defmodule Lanttern.Repo.Migrations.AddExtraFieldsToCurriculumComponents do
  use Ecto.Migration

  def change do
    alter table(:curriculum_components) do
      add :position, :integer, default: 0, null: false
      add :description, :text
      add :bg_color, :string
      add :text_color, :string
    end

    create constraint(
             :curriculum_components,
             :bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :curriculum_components,
             :text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
