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
      |> maybe_inject_school_id()
      |> maybe_inject_created_by_staff_member_id()
      |> maybe_inject_students_ids()
      |> maybe_inject_tags_ids()
      |> maybe_inject_status_id()
      |> Enum.into(%{
        date: ~D[2024-09-15],
        description: "some description",
        name: "some name",
        time: ~T[14:00:00]
      })
      |> Lanttern.StudentsRecords.create_student_record()

    student_record
  end

  @doc """
  Generate a student_record_tag.
  """
  def student_record_tag_fixture(attrs \\ %{}) do
    {:ok, student_record_tag} =
      attrs
      |> Enum.into(%{
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs),
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      })
      |> Lanttern.StudentsRecords.create_student_record_tag()

    student_record_tag
  end

  @doc """
  Generate a student_record_status.
  """
  def student_record_status_fixture(attrs \\ %{}) do
    {:ok, student_record_status} =
      attrs
      |> Enum.into(%{
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs),
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      })
      |> Lanttern.StudentsRecords.create_student_record_status()

    student_record_status
  end

  # generator helpers

  def maybe_gen_student_record_tags_ids(attrs, school_id \\ nil)

  def maybe_gen_student_record_tags_ids(%{tags_ids: tags_ids}, _), do: tags_ids

  def maybe_gen_student_record_tags_ids(_attrs, school_id),
    do: [student_record_tag_fixture(%{school_id: school_id}).id]

  # helpers

  defp maybe_inject_school_id(%{school_id: _} = attrs), do: attrs

  defp maybe_inject_school_id(attrs) do
    attrs
    |> Map.put(:school_id, SchoolsFixtures.school_fixture().id)
  end

  defp maybe_inject_created_by_staff_member_id(%{created_by_staff_member_id: _} = attrs),
    do: attrs

  defp maybe_inject_created_by_staff_member_id(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(
      :created_by_staff_member_id,
      SchoolsFixtures.staff_member_fixture(%{school_id: school_id}).id
    )
  end

  defp maybe_inject_students_ids(%{students_ids: _} = attrs), do: attrs

  defp maybe_inject_students_ids(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:students_ids, [SchoolsFixtures.student_fixture(%{school_id: school_id}).id])
  end

  defp maybe_inject_tags_ids(%{tags_ids: _} = attrs), do: attrs

  defp maybe_inject_tags_ids(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:tags_ids, [student_record_tag_fixture(%{school_id: school_id}).id])
  end

  defp maybe_inject_status_id(%{status_id: _} = attrs), do: attrs

  defp maybe_inject_status_id(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:status_id, student_record_status_fixture(%{school_id: school_id}).id)
  end
end
