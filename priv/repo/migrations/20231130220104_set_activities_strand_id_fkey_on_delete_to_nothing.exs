defmodule Lanttern.Repo.Migrations.SetActivitiesStrandIdFkeyOnDeleteToNothing do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE activities
              DROP CONSTRAINT activities_strand_id_fkey,
              ADD CONSTRAINT activities_strand_id_fkey FOREIGN KEY (strand_id)
                REFERENCES strands (id);
            """,
            """
            ALTER TABLE activities
              DROP CONSTRAINT activities_strand_id_fkey,
              ADD CONSTRAINT activities_strand_id_fkey FOREIGN KEY (strand_id)
                REFERENCES strands (id) ON DELETE CASCADE;
            """
  end
end
