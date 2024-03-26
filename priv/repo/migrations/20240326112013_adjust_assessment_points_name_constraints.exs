defmodule Lanttern.Repo.Migrations.AdjustAssessmentPointsNameConstraints do
  use Ecto.Migration

  # the name field should only be required when registering a assessment point
  # in the context of a moment. for strands (strand goal) it's not required

  def change do
    execute "ALTER TABLE assessment_points ALTER COLUMN name DROP NOT NULL",
            "ALTER TABLE assessment_points ALTER COLUMN name SET NOT NULL"

    # name is required only in moment context

    create constraint(
             :assessment_points,
             :required_name_except_in_strand_context,
             check: "strand_id IS NOT NULL OR name IS NOT NULL"
           )
  end
end
