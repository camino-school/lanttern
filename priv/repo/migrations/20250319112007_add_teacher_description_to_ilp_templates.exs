defmodule Lanttern.Repo.Migrations.AddTeacherDescriptionToIlpTemplates do
  use Ecto.Migration

  def change do
    alter table(:ilp_templates) do
      add :teacher_description, :text
    end
  end
end
