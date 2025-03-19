defmodule Lanttern.Repo.Migrations.AddAiFieldsToStudentsIlps do
  use Ecto.Migration

  def change do
    alter table(:students_ilps) do
      add :ai_revision, :text
      add :last_ai_revision_input, :text
      add :ai_revision_datetime, :utc_datetime
    end
  end
end
