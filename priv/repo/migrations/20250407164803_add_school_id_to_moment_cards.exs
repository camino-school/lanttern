defmodule Lanttern.Repo.Migrations.AddSchoolIdToMomentCards do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:moment_cards) do
      # create as nullable, but set null false after execute
      add :school_id, references(:schools, on_delete: :nothing)
    end

    create index(:moment_cards, [:school_id])

    # adding school_id to all moment_cards
    # (not a very precise query, but should be ok for now)
    execute """
            update moment_cards set school_id = s.id
            from (
              select id from schools
              order by id asc
              limit 1
            ) as s
            """,
            ""

    # set school_id to not null
    execute "alter table moment_cards alter column school_id set not null", ""

    # add field to log table
    alter table(:moment_cards, prefix: @prefix) do
      add :school_id, :bigint
    end
  end
end
