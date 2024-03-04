defmodule Lanttern.Repo.Migrations.SetCurriculumItemsYearsAndSubjectsOnDeleteCascade do
  use Ecto.Migration

  def change do
    # curriculum_items_subjects
    execute """
            ALTER TABLE curriculum_items_subjects
              DROP CONSTRAINT curriculum_items_subjects_curriculum_item_id_fkey,
              ADD CONSTRAINT curriculum_items_subjects_curriculum_item_id_fkey FOREIGN KEY (curriculum_item_id)
                REFERENCES curriculum_items (id) ON DELETE CASCADE;
            """,
            """
            ALTER TABLE curriculum_items_subjects
              DROP CONSTRAINT curriculum_items_subjects_curriculum_item_id_fkey,
              ADD CONSTRAINT curriculum_items_subjects_curriculum_item_id_fkey FOREIGN KEY (curriculum_item_id)
                REFERENCES curriculum_items (id);
            """

    execute """
            ALTER TABLE curriculum_items_subjects
              DROP CONSTRAINT curriculum_items_subjects_subject_id_fkey,
              ADD CONSTRAINT curriculum_items_subjects_subject_id_fkey FOREIGN KEY (subject_id)
                REFERENCES subjects (id) ON DELETE CASCADE;
            """,
            """
            ALTER TABLE curriculum_items_subjects
              DROP CONSTRAINT curriculum_items_subjects_subject_id_fkey,
              ADD CONSTRAINT curriculum_items_subjects_subject_id_fkey FOREIGN KEY (subject_id)
                REFERENCES subjects (id);
            """

    # curriculum_items_years
    execute """
            ALTER TABLE curriculum_items_years
              DROP CONSTRAINT curriculum_items_years_curriculum_item_id_fkey,
              ADD CONSTRAINT curriculum_items_years_curriculum_item_id_fkey FOREIGN KEY (curriculum_item_id)
                REFERENCES curriculum_items (id) ON DELETE CASCADE;
            """,
            """
            ALTER TABLE curriculum_items_years
              DROP CONSTRAINT curriculum_items_years_curriculum_item_id_fkey,
              ADD CONSTRAINT curriculum_items_years_curriculum_item_id_fkey FOREIGN KEY (curriculum_item_id)
                REFERENCES curriculum_items (id);
            """

    execute """
            ALTER TABLE curriculum_items_years
              DROP CONSTRAINT curriculum_items_years_year_id_fkey,
              ADD CONSTRAINT curriculum_items_years_year_id_fkey FOREIGN KEY (year_id)
                REFERENCES years (id) ON DELETE CASCADE;
            """,
            """
            ALTER TABLE curriculum_items_years
              DROP CONSTRAINT curriculum_items_years_year_id_fkey,
              ADD CONSTRAINT curriculum_items_years_year_id_fkey FOREIGN KEY (year_id)
                REFERENCES years (id);
            """
  end
end
