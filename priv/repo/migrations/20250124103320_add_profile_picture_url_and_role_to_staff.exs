defmodule Lanttern.Repo.Migrations.AddProfilePictureUrlAndRoleToStaff do
  use Ecto.Migration

  def change do
    alter table(:staff) do
      add :profile_picture_url, :text
      add :role, :text, null: false, default: "Teacher"
    end
  end
end
