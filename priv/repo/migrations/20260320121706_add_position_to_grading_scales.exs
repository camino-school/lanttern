defmodule Lanttern.Repo.Migrations.AddPositionToGradingScales do
  use Ecto.Migration

  def change do
    alter table(:grading_scales) do
      add :position, :integer, default: 0, null: false
    end

    create index(:grading_scales, [:position])
  end
end
