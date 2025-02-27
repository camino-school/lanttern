defmodule Lanttern.Repo.Migrations.CreateIlpEntries do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that component and
    # student ilp are linked to the same template.

    # removing existing "students_ilps_template_id_index" to prevent unnecessary index
    drop index(:students_ilps, [:template_id])
    create unique_index(:students_ilps, [:template_id, :id])

    create table(:ilp_entries) do
      add :description, :text

      add :student_ilp_id,
          references(:students_ilps, with: [template_id: :template_id], on_delete: :delete_all),
          null: false

      add :component_id,
          references(:ilp_components, with: [template_id: :template_id], on_delete: :nothing),
          null: false

      add :template_id, references(:ilp_templates, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:ilp_entries, [:student_ilp_id])
    create unique_index(:ilp_entries, [:component_id, :student_ilp_id])
    create index(:ilp_entries, [:template_id])
  end
end
