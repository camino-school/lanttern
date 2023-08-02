defmodule Lanttern.Repo.Migrations.ReferenceScaleInGradeCompositions do
  use Ecto.Migration

  def change do
    alter table(:grade_compositions) do
      add :final_grade_scale_id, references(:grading_scales, on_delete: :nothing), null: false
    end

    create index(:grade_compositions, [:final_grade_scale_id])
  end
end
