defmodule Lanttern.Repo.Migrations.AddCoverImageUrlToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :cover_image_url, :text
    end
  end
end
