defmodule Lanttern.Repo.Migrations.SetIcuCollationOnNameColumns do
  use Ecto.Migration

  # Pinning an explicit ICU collation makes `ORDER BY name` accent-aware (e.g.
  # "Érico" sorts right after "Eric", not after "Queiroz") and consistent across
  # environments, without per-query COLLATE fragments. `und-x-icu` is the Unicode
  # root collation; it is deterministic, so unique indexes and pg_trgm/LIKE keep
  # working unchanged.
  @icu_collation "und-x-icu"

  # `text` columns whose `name` is ordered alphabetically across the app.
  @text_tables ~w(
    students
    staff
    schools
    classes
    school_cycles
    years
    subjects
    schools_student_tags
    schools_students_records_tags
    student_record_statuses
    students_records
    moment_cards_templates
    curricula
    curriculum_items
    strands
    ai_agents
    ilp_templates
    lesson_templates
  )

  def up do
    for table <- @text_tables do
      execute(
        ~s|ALTER TABLE #{table} ALTER COLUMN name SET DATA TYPE text COLLATE "#{@icu_collation}"|
      )
    end

    # guardians.name is varchar(255); normalize it to text (matching every other
    # name column) while applying the collation.
    execute(
      ~s|ALTER TABLE guardians ALTER COLUMN name SET DATA TYPE text COLLATE "#{@icu_collation}"|
    )

    # school_lesson_tags.name stays varchar(255); only add the collation.
    execute(
      ~s|ALTER TABLE school_lesson_tags ALTER COLUMN name SET DATA TYPE varchar(255) COLLATE "#{@icu_collation}"|
    )
  end

  def down do
    for table <- @text_tables do
      execute(
        ~s|ALTER TABLE #{table} ALTER COLUMN name SET DATA TYPE text COLLATE pg_catalog."default"|
      )
    end

    execute(
      ~s|ALTER TABLE guardians ALTER COLUMN name SET DATA TYPE varchar(255) COLLATE pg_catalog."default"|
    )

    execute(
      ~s|ALTER TABLE school_lesson_tags ALTER COLUMN name SET DATA TYPE varchar(255) COLLATE pg_catalog."default"|
    )
  end
end
