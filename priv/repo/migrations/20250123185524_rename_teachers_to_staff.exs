defmodule Lanttern.Repo.Migrations.RenameTeachersToStaff do
  use Ecto.Migration

  def up do
    ##### teachers

    # teachers table rename
    rename table(:teachers), to: table(:staff)

    # rename indexes
    execute "ALTER INDEX teachers_pkey RENAME TO staff_pkey"
    execute "ALTER INDEX teachers_school_id_index RENAME TO staff_school_id_index"
    execute "ALTER INDEX teachers_name_school_id_index RENAME TO staff_name_school_id_index"

    # rename foreign keys
    execute "ALTER TABLE staff RENAME CONSTRAINT teachers_school_id_fkey TO staff_school_id_fkey"

    # rename sequence
    execute "ALTER SEQUENCE teachers_id_seq RENAME TO staff_id_seq"

    ##### profiles

    # profiles table rename
    rename table(:profiles), :teacher_id, to: :staff_member_id

    # rename indexes
    execute "ALTER INDEX profiles_teacher_id_index RENAME TO profiles_staff_member_id_index"

    # rename foreign keys
    execute "ALTER TABLE profiles RENAME CONSTRAINT profiles_teacher_id_fkey TO profiles_staff_member_id_fkey"

    # handle check constraint
    drop constraint(:profiles, :required_type_related_foreign_key)

    execute """
    update profiles
    set type = 'staff'
    where type = 'teacher'
    """

    check_constraint = """
    (type = 'student' AND student_id IS NOT NULL AND staff_member_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'staff' AND staff_member_id IS NOT NULL AND student_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'guardian' AND guardian_of_student_id IS NOT NULL AND staff_member_id IS NULL AND student_id IS NULL)
    """

    create constraint(
             :profiles,
             :required_type_related_foreign_key,
             check: check_constraint
           )
  end

  def down do
    ##### profiles

    # handle check constraint
    drop constraint(:profiles, :required_type_related_foreign_key)

    execute """
    update profiles
    set type = 'teacher'
    where type = 'staff'
    """

    check_constraint = """
    (type = 'student' AND student_id IS NOT NULL AND staff_member_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'teacher' AND staff_member_id IS NOT NULL AND student_id IS NULL AND guardian_of_student_id IS NULL)
    OR (type = 'guardian' AND guardian_of_student_id IS NOT NULL AND staff_member_id IS NULL AND student_id IS NULL)
    """

    create constraint(
             :profiles,
             :required_type_related_foreign_key,
             check: check_constraint
           )

    # rename foreign keys
    execute "ALTER TABLE profiles RENAME CONSTRAINT profiles_staff_member_id_fkey TO profiles_teacher_id_fkey"

    # rename indexes
    execute "ALTER INDEX profiles_staff_member_id_index RENAME TO profiles_teacher_id_index"

    # profiles table rename
    rename table(:profiles), :staff_member_id, to: :teacher_id

    ##### teachers

    # rename sequence
    execute "ALTER SEQUENCE staff_id_seq RENAME TO teachers_id_seq"

    # rename foreign keys
    execute "ALTER TABLE staff RENAME CONSTRAINT staff_school_id_fkey TO teachers_school_id_fkey"

    # rename indexes
    execute "ALTER INDEX staff_pkey RENAME TO teachers_pkey"
    execute "ALTER INDEX staff_school_id_index RENAME TO teachers_school_id_index"
    execute "ALTER INDEX staff_name_school_id_index RENAME TO teachers_name_school_id_index"

    # teachers table rename
    rename table(:staff), to: table(:teachers)
  end
end
