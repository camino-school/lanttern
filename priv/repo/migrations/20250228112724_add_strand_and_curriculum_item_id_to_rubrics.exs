defmodule Lanttern.Repo.Migrations.AddStrandAndCurriculumItemIdToRubrics do
  use Ecto.Migration

  def change do
    alter table(:rubrics) do
      add :position, :integer, default: 0, null: false

      # it's null: false for both, but we need to migrate data before adding the constraint
      add :strand_id, references(:strands, on_delete: :nothing)
      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing)
    end

    # create as unique_index to allow composite fk in assessment points
    create unique_index(:rubrics, [:strand_id, :id])
    create unique_index(:rubrics, [:curriculum_item_id, :id])

    # populate strand and curriculum item ids fields based on
    # assessment points / rubrics relationship
    execute """
            update rubrics r
            set
              strand_id = ap.strand_id,
              curriculum_item_id = ap.curriculum_item_id
            from assessment_points ap
            where
              (ap.rubric_id = r.id or ap.rubric_id = r.diff_for_rubric_id)
              and ap.strand_id is not null
            """,
            ""

    # consider every rubric with "diff_for_rubric_id" as a differentiation rubric
    execute """
            update rubrics
            set is_differentiation = true
            where diff_for_rubric_id is not null
            """,
            ""

    # remove all rubrics without a strand_id
    # (orphaned rubrics, they should have been removed)
    execute "delete from rubrics where strand_id is null", ""

    # finally, set strand and curriculum item id to not null
    execute "alter table rubrics alter column strand_id set not null", ""
    execute "alter table rubrics alter column curriculum_item_id set not null", ""
  end
end
