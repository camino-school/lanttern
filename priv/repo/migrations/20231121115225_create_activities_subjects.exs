defmodule Lanttern.Repo.Migrations.CreateActivitiesSubjects do
  use Ecto.Migration

  def change do
    create table(:activities_subjects, primary_key: false) do
      add :activity_id, references(:activities, on_delete: :delete_all), null: false
      add :subject_id, references(:subjects, on_delete: :delete_all), null: false
    end

    create index(:activities_subjects, [:activity_id])
    create unique_index(:activities_subjects, [:subject_id, :activity_id])
  end
end
