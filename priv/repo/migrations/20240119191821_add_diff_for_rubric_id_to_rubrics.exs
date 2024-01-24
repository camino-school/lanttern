defmodule Lanttern.Repo.Migrations.AddDiffForRubricIdToRubrics do
  use Ecto.Migration

  def change do
    alter table(:rubrics) do
      add :diff_for_rubric_id, references(:rubrics)
    end

    create index(:rubrics, [:diff_for_rubric_id])
  end
end
