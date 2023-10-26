defmodule Lanttern.Repo.Migrations.CreateRubrics do
  use Ecto.Migration

  def change do
    create table(:rubrics) do
      add :criteria, :text, null: false
      add :is_differentiation, :boolean, default: false, null: false
      add :scale_id, references(:grading_scales, on_delete: :nothing)

      timestamps()
    end

    create index(:rubrics, [:scale_id])
  end
end
