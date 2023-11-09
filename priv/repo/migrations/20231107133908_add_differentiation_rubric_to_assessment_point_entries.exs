defmodule Lanttern.Repo.Migrations.AddDifferentiationRubricToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      # `scale_id` and `scale_type` are `null: false`.
      # we'll add this in the execute blocks below
      # after we add the correct scale ids and types to all entries

      add :scale_id, references(:grading_scales, on_delete: :nothing)

      add :scale_type,
          references(:grading_scales,
            column: :type,
            type: :text,
            with: [scale_id: :id],
            on_delete: :nothing
          )

      add :differentiation_rubric_id,
          references(:rubrics,
            with: [scale_id: :scale_id],
            on_delete: :nilify_all
          )
    end

    create index(:assessment_point_entries, [:differentiation_rubric_id])

    # adding scale ids and types to each entry, based on parent assessment point
    execute """
            UPDATE assessment_point_entries
            SET scale_id=subquery.scale_id,
                scale_type=subquery.scale_type
            FROM (
              SELECT
                assessment_points.id as assessment_point_id,
                grading_scales.id as scale_id,
                grading_scales.type as scale_type
              FROM grading_scales
              JOIN assessment_points ON assessment_points.scale_id = grading_scales.id
            ) AS subquery
            WHERE assessment_point_entries.assessment_point_id = subquery.assessment_point_id
            """,
            ""

    # add not null constraints to scale fields
    execute "ALTER TABLE assessment_point_entries ALTER COLUMN scale_id SET NOT NULL", ""
    execute "ALTER TABLE assessment_point_entries ALTER COLUMN scale_type SET NOT NULL", ""

    # remove ordinal value fk constraint and recreate it using composite foreign keys
    execute """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_ordinal_value_id_fkey
            """,
            """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_ordinal_value_id_fkey
                FOREIGN KEY (ordinal_value_id)
                  REFERENCES ordinal_values(id)
            """

    execute """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_ordinal_value_id_fkey
                FOREIGN KEY (ordinal_value_id, scale_id)
                  REFERENCES ordinal_values(id, scale_id)
            """,
            """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_ordinal_value_id_fkey
            """
  end
end
