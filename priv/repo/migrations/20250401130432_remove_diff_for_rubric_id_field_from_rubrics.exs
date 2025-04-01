defmodule Lanttern.Repo.Migrations.RemoveDiffForRubricIdFieldFromRubrics do
  use Ecto.Migration

  def change do
    alter table(:rubrics) do
      remove :diff_for_rubric_id, references(:rubrics)
    end
  end
end
