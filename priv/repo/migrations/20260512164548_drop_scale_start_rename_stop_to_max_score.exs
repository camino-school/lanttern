defmodule Lanttern.Repo.Migrations.DropScaleStartRenameStopToMaxScore do
  use Ecto.Migration

  def change do
    alter table(:grading_scales) do
      remove :start
    end

    rename table(:grading_scales), :stop, to: :max_score
  end
end
