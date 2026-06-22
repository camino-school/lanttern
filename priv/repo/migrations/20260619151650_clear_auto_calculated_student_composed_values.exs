defmodule Lanttern.Repo.Migrations.ClearAutoCalculatedStudentComposedValues do
  use Ecto.Migration

  # Composed assessment points used to auto-calculate the student edit domain
  # (`student_score` / `student_ordinal_value_id` / `student_normalized_value`)
  # on every component update, alongside the teacher domain. Those derived values
  # surfaced in the student/guardian view as a self-assessment, which they never
  # were — the student input is disabled for composed assessment points, so the
  # only way these fields got populated was the automatic calculation.
  #
  # The application no longer derives composed student entries automatically
  # (pending a redesign of student self-assessment). This one-off data migration
  # clears the stale auto-calculated values left behind, so they stop showing up
  # as a self-assessment. The teacher domain is intentionally left untouched.
  #
  # Irreversible: the cleared values were derived, not entered, and would be
  # recomputed by a future redesign — so `down` is a no-op rather than a guess.
  #
  # This bulk UPDATE intentionally bypasses the `log.assessment_point_entries`
  # audit mirror (written by application code, not a DB trigger). The audit log
  # tracks user-entered changes; these values were never user input, so they are
  # corrected here without a corresponding log row. Historical log rows that may
  # already record the auto-calculated values are left as-is — point-in-time
  # records of what the system computed at the time.

  def up do
    execute("""
    UPDATE assessment_point_entries AS e
    SET student_score = NULL,
        student_ordinal_value_id = NULL,
        student_normalized_value = NULL
    FROM assessment_points AS ap
    WHERE e.assessment_point_id = ap.id
      AND ap.uses_composition = true
      AND (e.student_score IS NOT NULL
           OR e.student_ordinal_value_id IS NOT NULL
           OR e.student_normalized_value IS NOT NULL)
    """)
  end

  def down, do: :ok
end
