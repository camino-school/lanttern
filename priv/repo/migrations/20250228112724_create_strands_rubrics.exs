defmodule Lanttern.Repo.Migrations.CreateStrandsRubrics do
  use Ecto.Migration

  def change do
    create table(:strands_rubrics) do
      add :is_differentiation, :boolean, default: false, null: false
      add :position, :integer, default: 0, null: false
      add :strand_id, references(:strands, on_delete: :nothing), null: false

      add :rubric_id, references(:rubrics, with: [scale_id: :scale_id], on_delete: :delete_all),
        null: false

      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing), null: false
      add :scale_id, references(:grading_scales, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:strands_rubrics, [:strand_id])
    create index(:strands_rubrics, [:rubric_id])
    create unique_index(:strands_rubrics, [:curriculum_item_id, :strand_id, :rubric_id])
    # use unique index to allow composite fk on assessment points
    create unique_index(:strands_rubrics, [:scale_id, :id])
    create unique_index(:strands_rubrics, [:curriculum_item_id, :id])

    # populate strands rubrics based on assessment points info
    execute """
            insert into strands_rubrics (
              strand_id,
              rubric_id,
              curriculum_item_id,
              scale_id,
              inserted_at,
              updated_at
            )
            select
              strand_id,
              rubric_id,
              curriculum_item_id,
              scale_id,
              inserted_at,
              updated_at
            from assessment_points
            where
              rubric_id is not null
              and strand_id is not null
            """,
            ""

    # also include diff rubrics
    execute """
            insert into strands_rubrics (
              is_differentiation,
              position,
              strand_id,
              rubric_id,
              curriculum_item_id,
              scale_id,
              inserted_at,
              updated_at
            )
            select
              true is_differentiation,
              1 position,
              ap.strand_id,
              diff_r.id,
              ap.curriculum_item_id,
              ap.scale_id,
              ap.inserted_at,
              ap.updated_at
            from assessment_points ap
            join rubrics r on r.id = ap.rubric_id
            join rubrics diff_r on diff_r.diff_for_rubric_id = r.id
            where ap.strand_id is not null
            """,
            ""
  end
end
