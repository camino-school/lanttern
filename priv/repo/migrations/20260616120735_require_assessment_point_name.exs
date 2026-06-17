defmodule Lanttern.Repo.Migrations.RequireAssessmentPointName do
  use Ecto.Migration

  def up do
    # backfill null names with the component-prefixed curriculum item label,
    # matching how nameless (strand-context) assessment points are displayed today
    execute("""
    UPDATE assessment_points ap
    SET name = '(' || cc.name || ') ' || ci.name
    FROM curriculum_items ci
    JOIN curriculum_components cc ON cc.id = ci.curriculum_component_id
    WHERE ap.curriculum_item_id = ci.id
      AND ap.name IS NULL
    """)

    # the conditional constraint is now redundant: name is required everywhere
    drop(constraint(:assessment_points, :required_name_except_in_strand_context))

    execute("ALTER TABLE assessment_points ALTER COLUMN name SET NOT NULL")
  end

  def down do
    execute("ALTER TABLE assessment_points ALTER COLUMN name DROP NOT NULL")

    create(
      constraint(:assessment_points, :required_name_except_in_strand_context,
        check: "strand_id IS NOT NULL OR name IS NOT NULL"
      )
    )

    # backfilled names are intentionally not reverted
  end
end
