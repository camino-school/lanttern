defmodule Lanttern.Repo.Migrations.AddSchoolIdIntoScaleTable do
  @moduledoc """
  Adds school_id and disabled_at fields to the scales table.
  """
  use Ecto.Migration

  def change do
    alter table(:grading_scales) do
      add :school_id, references(:schools, on_delete: :delete_all)
      add :deactivated_at, :utc_datetime
    end

    create index(:grading_scales, [:school_id])
  end
end
