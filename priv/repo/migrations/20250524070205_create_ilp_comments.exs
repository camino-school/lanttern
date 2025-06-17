defmodule Lanttern.Repo.Migrations.CreateIlpComments do
  use Ecto.Migration

  def change do
    create table(:ilp_comments) do
      add :name, :string
      add :content, :text
      add :position, :integer
      add :shared_with_students, :boolean, default: false, null: false
      add :student_ilp_id, references(:students_ilps, on_delete: :nilify_all)
      add :owner_id, references(:profiles, on_delete: :nilify_all)

      timestamps()
    end

    create index(:ilp_comments, [:student_ilp_id])
    create index(:ilp_comments, [:owner_id])
  end
end
