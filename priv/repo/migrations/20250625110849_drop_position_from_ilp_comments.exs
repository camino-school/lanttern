defmodule Lanttern.Repo.Migrations.DropPositionFromIlpComments do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:ilp_comments) do
      remove :position, :integer
    end

    alter table(:ilp_comments, prefix: @prefix) do
      remove :position, :integer, default: 0, null: false
    end
  end
end
