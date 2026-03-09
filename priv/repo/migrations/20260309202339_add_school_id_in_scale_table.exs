defmodule Lanttern.Repo.Migrations.AddSchoolIdIntoScaleTable do
  use Ecto.Migration

  def change do
    alter table(:scales) do
      add :school_id, references(:schools, on_delete: :cascade)
      add :disabled_at, :utc_datetime
    end

    create index(:scales, [:school_id])
  end
end
