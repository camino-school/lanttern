defmodule Lanttern.Repo.Migrations.AddCycleToClasses do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the selected cycle
    # belongs to the same school of the class.

    # removing existing "school_cycles_school_id_index" to prevent unnecessary index
    drop index(:school_cycles, [:school_id])
    create unique_index(:school_cycles, [:school_id, :id])

    alter table(:classes) do
      # `cycle_id` is `null: false`.
      # we'll add this in the execute blocks below
      # after we add a scale to all classes

      add :cycle_id,
          references(:school_cycles,
            with: [school_id: :school_id],
            on_delete: :nothing
          )
    end

    create index(:classes, [:cycle_id])

    # creating one temp cycle to each school in the database
    execute """
            INSERT INTO school_cycles (name, start_at, end_at, school_id, inserted_at, updated_at)
            SELECT
              'TEMP ' || date_part('year', CURRENT_DATE)::text,
              make_date(date_part('year', CURRENT_DATE)::int, 1, 1),
              make_date(date_part('year', CURRENT_DATE)::int, 12, 31),
              schools.id,
              now() AT time zone 'utc',
              now() AT time zone 'utc'
            FROM schools
            """,
            ""

    # link temp cycles to existing classes
    execute """
            UPDATE classes SET cycle_id = school_cycles.id
            FROM school_cycles
            WHERE school_cycles.school_id = classes.school_id
            """,
            ""

    # add not null constraints to classes' cycle_id
    execute "ALTER TABLE classes ALTER COLUMN cycle_id SET NOT NULL", ""
  end
end
