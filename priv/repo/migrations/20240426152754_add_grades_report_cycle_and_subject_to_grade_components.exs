defmodule Lanttern.Repo.Migrations.AddGradesReportCycleAndSubjectToGradeComponents do
  use Ecto.Migration

  # MIGRATION PLAN
  # 1. add grades_report_id, grades_report_cycle_id, and grades_report_subject_id (nullable, will change after transfer)
  # 2. delete "orphaned" grade components (when linked to a report card that is not linked to a grades report)
  # 3. connect to grades_report_id based on report_card > grades_report relationship
  # 4. connect to grades_report_cycle_id based on report_card > grades_report relationship (get cycle id from report card)
  # 5. connect to grades_report_subject_id based on report_card > grades_report relationship (get subject from the grade component itself)
  # 6. make grades_report_id, grades_report_cycle_id, and grades_report_subject_id NOT NULL
  # 7. remove subject_id and report_card_id (not reversible)

  def up do
    # 1 add grades report cycle and subject columns

    alter table(:grade_components) do
      add :grades_report_id, references(:grades_reports, on_delete: :nothing)

      # use composite foreign keys.
      # this guarantees, in the database level, that the grades report
      # cycles and subjects belongs to the same grades report

      add :grades_report_cycle_id,
          references(:grades_report_cycles,
            with: [grades_report_id: :grades_report_id],
            on_delete: :nothing
          )

      add :grades_report_subject_id,
          references(:grades_report_subjects,
            with: [grades_report_id: :grades_report_id],
            on_delete: :nothing
          )
    end

    create index(:grade_components, [:grades_report_id])
    create index(:grade_components, [:grades_report_cycle_id])

    create unique_index(:grade_components, [
             :grades_report_subject_id,
             :grades_report_cycle_id,
             :assessment_point_id
           ])

    # 2 delete orphaned grade components

    execute """
    DELETE FROM grade_components
    WHERE grade_components.id IN (
      SELECT gc.id FROM grade_components gc
      JOIN report_cards rc ON rc.id = gc.report_card_id
      LEFT JOIN grades_reports gr ON gr.id = rc.grades_report_id
      WHERE gr.id IS NULL
    )
    """

    # 4 set grades_report_id

    execute """
    UPDATE grade_components
    SET grades_report_id = subquery.grades_report_id
    FROM (
      SELECT
        gc.id AS grade_component_id,
        gr.id AS grades_report_id
      FROM grade_components gc
      JOIN report_cards rc ON rc.id = gc.report_card_id
      JOIN grades_reports gr ON gr.id = rc.grades_report_id
    ) AS subquery
    WHERE grade_components.id = subquery.grade_component_id
    """

    # 4 set grades_report_cycle_id

    execute """
    UPDATE grade_components
    SET grades_report_cycle_id = subquery.grades_report_cycle_id
    FROM (
      SELECT
        gc.id AS grade_component_id,
        grc.id AS grades_report_cycle_id
      FROM grade_components gc
      JOIN report_cards rc ON rc.id = gc.report_card_id
      JOIN grades_reports gr ON gr.id = rc.grades_report_id
      JOIN grades_report_cycles grc ON grc.grades_report_id = gr.id AND grc.school_cycle_id = rc.school_cycle_id
    ) AS subquery
    WHERE grade_components.id = subquery.grade_component_id
    """

    # 5 set grades_report_subject_id

    execute """
    UPDATE grade_components
    SET grades_report_subject_id = subquery.grades_report_subject_id
    FROM (
      SELECT
        gc.id AS grade_component_id,
        grs.id AS grades_report_subject_id
      FROM grade_components gc
      JOIN report_cards rc ON rc.id = gc.report_card_id
      JOIN grades_reports gr ON gr.id = rc.grades_report_id
      JOIN grades_report_subjects grs ON grs.grades_report_id = gr.id AND grs.subject_id = gc.subject_id
    ) AS subquery
    WHERE grade_components.id = subquery.grade_component_id
    """

    # 6. set NOT NULL

    execute "ALTER TABLE grade_components ALTER COLUMN grades_report_id SET NOT NULL"
    execute "ALTER TABLE grade_components ALTER COLUMN grades_report_cycle_id SET NOT NULL"
    execute "ALTER TABLE grade_components ALTER COLUMN grades_report_subject_id SET NOT NULL"

    # 7 remove subject_id and report_card_id

    alter table(:grade_components) do
      remove :subject_id
      remove :report_card_id
    end
  end

  def down do
    # ROLLBACK STRATEGY (data loss will occur)
    # 7. delete all grade components
    # 6. add subject_id and report_card_id
    # 5. -
    # 4. -
    # 3. -
    # 2. -
    # 1. remove grades_report_cycle_id and grades_report_subject_id

    # 7. delete all grade components

    execute "DELETE FROM grade_components"

    # 6. add subject_id and report_card_id

    alter table(:grade_components) do
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
    end

    create index(:grade_components, [:report_card_id])
    create unique_index(:grade_components, [:subject_id, :assessment_point_id, :report_card_id])

    # 1. remove(grades_report_cycle_id and grades_report_subject_id)

    alter table(:grade_components) do
      remove :grades_report_cycle_id
      remove :grades_report_subject_id
    end
  end
end
