defmodule Lanttern.Repo.Migrations.CreateNameConstraints do
  use Ecto.Migration

  def change do
    alter table(:students) do
      modify :name, :text, null: false, from: {:text, null: true}
    end

    alter table(:curriculum_items) do
      modify :name, :text, null: false, from: {:text, null: true}
    end

    alter table(:grade_compositions) do
      modify :name, :text, null: false, from: {:text, null: true}
    end
  end
end
