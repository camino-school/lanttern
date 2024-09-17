defmodule Lanttern.StudentsRecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.StudentsRecords` context.
  """

  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a student_record.
  """
  def student_record_fixture(attrs \\ %{}) do
    {:ok, student_record} =
      attrs
      |> Enum.into(%{
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs),
        date: ~D[2024-09-15],
        description: "some description",
        name: "some name",
        time: ~T[14:00:00]
      })
      |> Lanttern.StudentsRecords.create_student_record()

    student_record
  end

  @doc """
  Generate a student_record_type.
  """
  def student_record_type_fixture(attrs \\ %{}) do
    {:ok, student_record_type} =
      attrs
      |> Enum.into(%{
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs),
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      })
      |> Lanttern.StudentsRecords.create_student_record_type()

    student_record_type
  end
end
