defmodule Lanttern.Repo.Migrations.CreateRubricDescriptors do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the ordinal value
    # belongs to the same scale that is used in the parent rubric
    create unique_index(:rubrics, [:id, :scale_id])
    create unique_index(:grading_scales, [:id, :type])
    create unique_index(:ordinal_values, [:id, :scale_id])

    create table(:rubric_descriptors) do
      add :descriptor, :text, null: false

      add :rubric_id, references(:rubrics, with: [scale_id: :scale_id], on_delete: :delete_all),
        null: false

      add :scale_id, references(:grading_scales, on_delete: :nothing), null: false

      add :scale_type,
          references(:grading_scales,
            column: :type,
            type: :text,
            with: [scale_id: :id],
            on_delete: :nothing
          ),
          null: false

      add :score, :float

      add :ordinal_value_id,
          references(:ordinal_values, with: [scale_id: :scale_id], on_delete: :nothing)

      timestamps()
    end

    create index(:rubric_descriptors, [:rubric_id])
    create index(:rubric_descriptors, [:scale_id])
    create unique_index(:rubric_descriptors, [:ordinal_value_id, :rubric_id])

    # score is required when scale_type = 'numeric'
    # ordinal_value_id is required when scale_type = 'ordinal'
    check_constraint = """
    (scale_type = 'numeric' AND score IS NOT NULL AND ordinal_value_id IS NULL)
    OR (scale_type = 'ordinal' AND ordinal_value_id IS NOT NULL AND score IS NULL)
    """

    create constraint(
             :rubric_descriptors,
             :required_scale_type_related_value,
             check: check_constraint
           )
  end
end
