defmodule Lanttern.Repo.Migrations.CreateStudentsRecordsTags do
  use Ecto.Migration

  def up do
    ##### create new table schools_students_records_tags

    create table(:schools_students_records_tags) do
      add :name, :text, null: false
      add :bg_color, :string, null: false
      add :text_color, :string, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false
      add :position, :integer, null: false, default: 0

      timestamps()
    end

    create index(:schools_students_records_tags, [:position])
    create unique_index(:schools_students_records_tags, [:school_id, :id])

    create constraint(
             :schools_students_records_tags,
             :schools_students_records_tags_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :schools_students_records_tags,
             :schools_students_records_tags_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )

    ##### copy data from student_record_types to schools_students_records_tags

    execute """
    insert into schools_students_records_tags (id, name, bg_color, text_color, school_id, inserted_at, updated_at)
    select id, name, bg_color, text_color, school_id, inserted_at, updated_at
    from student_record_types
    """

    # adjust sequence
    execute "select setval('schools_students_records_tags_id_seq', (SELECT MAX(id) FROM schools_students_records_tags))"

    ##### create relationship table students_records_tags

    # use composite foreign keys to guarantee,
    # in the database level, that record and assignee
    # belong to the same school

    create table(:students_records_tags, primary_key: false) do
      add :student_record_id,
          references(:students_records, with: [school_id: :school_id], on_delete: :delete_all),
          primary_key: true

      add :tag_id,
          references(:schools_students_records_tags,
            with: [school_id: :school_id],
            # if we cascade when deleting a tag, the student record
            # may not have a tag anymore, which is not allowed
            on_delete: :nothing
          ),
          primary_key: true

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    ##### migrate data from students_records to students_records_tags
    execute """
    insert into students_records_tags (student_record_id, tag_id, school_id)
    select id as student_record_id, type_id as tag_id, school_id
    from students_records
    """

    ##### drop type_id column from students_records and drop student_record_types table
    alter table(:students_records) do
      remove :type_id
    end

    drop table(:student_record_types)
  end

  def down do
    #### recreate student_record_types table
    create table(:student_record_types) do
      add :name, :text, null: false
      add :bg_color, :string, null: false
      add :text_color, :string, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:student_record_types, [:school_id, :id])

    create constraint(
             :student_record_types,
             :student_record_type_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :student_record_types,
             :student_record_type_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )

    ##### copy data back from schools_students_records_tags to student_record_types

    execute """
    insert into student_record_types (id, name, bg_color, text_color, school_id, inserted_at, updated_at)
    select id, name, bg_color, text_color, school_id, inserted_at, updated_at
    from schools_students_records_tags
    """

    # adjust sequence
    execute "select setval('student_record_types_id_seq', (SELECT MAX(id) FROM student_record_types))"

    ##### recreate type_id column in students_records
    alter table(:students_records) do
      # `type_id` is `null: false`.
      # we'll add this in the execute blocks below
      # after we add a type to all records

      add :type_id,
          references(:student_record_types,
            with: [school_id: :school_id],
            on_delete: :nothing
          )
    end

    ##### migrate data back from students_records_tags
    execute """
    update students_records
    set type_id = students_records_tags.tag_id
    from students_records_tags
    where students_records_tags.student_record_id = students_records.id
    """

    # add not null constraints to students records' type_id
    execute "ALTER TABLE students_records ALTER COLUMN type_id SET NOT NULL", ""

    ##### drop relationship table students_records_tags
    drop table(:students_records_tags)

    ##### drop table schools_students_records_tags
    drop table(:schools_students_records_tags)
  end
end
