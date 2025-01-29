defmodule Lanttern.Repo.Migrations.AddTagsIdsToStudentsRecordsLogs do
  use Ecto.Migration

  @prefix "log"

  def change do
    # add tags_ids field to students records log
    alter table(:students_records, prefix: @prefix) do
      add :tags_ids, {:array, :bigint}
    end

    # when rolling back, set type_id to not null after setting values
    execute "",
            "ALTER TABLE log.students_records ALTER COLUMN type_id SET NOT NULL"

    # populate based on existing type_id
    execute """
              update log.students_records
              set tags_ids = array[type_id]
            """,
            """
              update log.students_records
              set type_id = tags_ids[1]
            """

    # drop type_id field from students records log
    alter table(:students_records, prefix: @prefix) do
      remove :type_id, :bigint
    end
  end
end
