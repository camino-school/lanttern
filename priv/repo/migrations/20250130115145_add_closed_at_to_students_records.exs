defmodule Lanttern.Repo.Migrations.AddClosedAtToStudentsRecords do
  use Ecto.Migration

  def change do
    alter table(:students_records) do
      add :closed_at, :utc_datetime
      add :closed_by_staff_member_id, references(:staff, on_delete: :nothing)

      add :duration_until_close, :duration,
        generated: """
          ALWAYS AS (CASE
            WHEN closed_at IS NOT NULL THEN closed_at - inserted_at
            ELSE NULL
          END) STORED
        """
    end

    create index(:students_records, [:closed_at])
    create index(:students_records, [:closed_by_staff_member_id])
    create index(:students_records, [:duration_until_close])

    create constraint(
             :students_records,
             :closed_by_staff_member_id_required_when_closed,
             check: "closed_at IS NULL OR closed_by_staff_member_id IS NOT NULL"
           )

    create constraint(
             :students_records,
             :closed_by_staff_member_id_only_allowed_when_closed,
             check: "closed_at IS NOT NULL OR closed_by_staff_member_id IS NULL"
           )

    # adding index to "old" columns we'll use to filter and sort records
    create index(:students_records, [:date])
    create index(:students_records, [:time])
    create index(:students_records, [:inserted_at])
  end
end
