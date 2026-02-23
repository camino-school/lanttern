defmodule Lanttern.Repo.Migrations.FixStudentsIlpsBaseUniqueIndex do
  use Ecto.Migration

  def up do
    drop_if_exists index(:students_ilps, [:student_id, :template_id, :cycle_id, :update_of_ilp_id])

    create_if_not_exists unique_index(:students_ilps, [:student_id, :template_id, :cycle_id],
      where: "update_of_ilp_id IS NULL"
    )
  end

  def down do
    drop_if_exists index(:students_ilps, [:student_id, :template_id, :cycle_id])

    create_if_not_exists unique_index(:students_ilps, [:student_id, :template_id, :cycle_id, :update_of_ilp_id],
      nulls_distinct: false
    )
  end
end
