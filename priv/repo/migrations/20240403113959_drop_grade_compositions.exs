defmodule Lanttern.Repo.Migrations.DropGradeCompositions do
  use Ecto.Migration

  def up do
    drop table(:grade_compositions)
  end

  def down do
    create table(:grade_compositions) do
      add :name, :text, null: false
      add :final_grade_scale_id, references(:grading_scales, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:grade_compositions, [:final_grade_scale_id])
  end
end
