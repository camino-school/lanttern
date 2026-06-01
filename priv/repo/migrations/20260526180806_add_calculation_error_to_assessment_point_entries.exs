defmodule Lanttern.Repo.Migrations.AddCalculationErrorToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :calculation_error, :string
    end
  end
end
