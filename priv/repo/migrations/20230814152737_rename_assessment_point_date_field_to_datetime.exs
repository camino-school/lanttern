defmodule Lanttern.Repo.Migrations.RenameAssessmentPointDateFieldToDatetime do
  use Ecto.Migration

  def change do
    rename table(:assessment_points), :date, to: :datetime
  end
end
