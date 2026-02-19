defmodule Lanttern.StudentsGuardians do
  @moduledoc """
  Deprecated: Student-Guardian relationship functions have been moved to `Lanttern.Schools` context.

  This module is kept for backward compatibility. Please use `Lanttern.Schools` instead.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  alias Lanttern.Schools
  alias Lanttern.Schools.Guardian
  alias Lanttern.Schools.Student

  @deprecated "Use Lanttern.Schools.get_students_for_guardian/2 instead"
  def get_students_for_guardian(scope, %Guardian{} = guardian) do
    Schools.get_students_for_guardian(scope, guardian)
  end

  @deprecated "Use Lanttern.Schools.get_guardians_for_student/2 instead"
  def get_guardians_for_student(scope, %Student{} = student) do
    Schools.get_guardians_for_student(scope, student)
  end

  @deprecated "Use Lanttern.Schools.add_guardian_to_student/3 instead"
  def add_guardian_to_student(scope, %Student{} = student, %Guardian{} = guardian) do
    Schools.add_guardian_to_student(scope, student, guardian)
  end

  @deprecated "Use Lanttern.Schools.remove_guardian_from_student/3 instead"
  def remove_guardian_from_student(scope, %Student{} = student, guardian_id) do
    Schools.remove_guardian_from_student(scope, student, guardian_id)
  end
end
