defmodule Lanttern.Repo.Migrations.CreateClassesStaffMembers do
  use Ecto.Migration

  def change do
    create table(:classes_staff_members) do
      add :class_id, references(:classes, on_delete: :delete_all), null: false
      add :staff_member_id, references(:staff, on_delete: :delete_all), null: false
      add :position, :integer, null: false, default: 0
      add :role, :string

      timestamps()
    end

    create index(:classes_staff_members, [:class_id])
    create index(:classes_staff_members, [:staff_member_id])
    create unique_index(:classes_staff_members, [:class_id, :staff_member_id])
    create index(:classes_staff_members, [:class_id, :position])
  end
end
