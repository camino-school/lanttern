defmodule Lanttern.Repo.Migrations.AddAssessmentInfoToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :assessment_info, :text
    end
  end
end
