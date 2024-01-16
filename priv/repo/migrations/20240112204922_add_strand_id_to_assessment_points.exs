defmodule Lanttern.Repo.Migrations.AddStrandIdToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :strand_id, references(:strands)
    end

    create index(:assessment_points, [:strand_id])

    # the assessment point can't belong
    # to an activity and a strand at the same time
    check_constraint = """
    activity_id IS NULL OR strand_id IS NULL
    """

    create constraint(
             :assessment_points,
             :ensure_only_one_context,
             check: check_constraint
           )
  end
end
