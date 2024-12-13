defmodule Lanttern.Repo.Migrations.ExecuteCreateStudentsRecordsClasses do
  use Ecto.Migration

  def change do
    execute """
            insert into students_records_classes (student_record_id, class_id, school_id)
            select distinct
              sr.id student_record_id,
              c.id class_id,
              c.school_id school_id
            from students_records sr
            join students_students_records ssr on ssr.student_record_id = sr.id
            join classes_students cs on cs.student_id = ssr.student_id
            join classes c on c.id = cs.class_id
            join school_cycles cy on cy.id = c.cycle_id
            where sr.date >= cy.start_at and sr.date <= cy.end_at
            """,
            ""
  end
end
