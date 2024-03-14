defmodule Lanttern.SchoolsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Schools` context.
  """

  @doc """
  Generate a school.
  """
  def school_fixture(attrs \\ %{}) do
    {:ok, school} =
      attrs
      |> Enum.into(%{
        name: "some school name"
      })
      |> Lanttern.Schools.create_school()

    school
  end

  @doc """
  Generate a cycle.
  """
  def cycle_fixture(attrs \\ %{}) do
    {:ok, cycle} =
      attrs
      |> Enum.into(%{
        school_id: maybe_gen_school_id(attrs),
        name: "some name",
        start_at: ~D[2023-11-09],
        end_at: ~D[2024-11-09]
      })
      |> Lanttern.Schools.create_cycle()

    cycle
  end

  @doc """
  Generate a class.
  """
  def class_fixture(attrs \\ %{})

  def class_fixture(%{cycle_id: cycle_id} = attrs) do
    {:ok, class} =
      attrs
      |> Enum.into(%{
        school_id: maybe_gen_school_id(attrs),
        cycle_id: cycle_id,
        name: "some class name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_class()

    class
  end

  def class_fixture(attrs) do
    school_id = maybe_gen_school_id(attrs)
    cycle = cycle_fixture(%{school_id: school_id})

    {:ok, class} =
      attrs
      |> Enum.into(%{
        school_id: school_id,
        cycle_id: cycle.id,
        name: "some class name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_class()

    class
  end

  @doc """
  Generate a student.
  """
  def student_fixture(attrs \\ %{}) do
    {:ok, student} =
      attrs
      |> Enum.into(%{
        school_id: maybe_gen_school_id(attrs),
        name: "some full name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_student()

    student
  end

  @doc """
  Generate a teacher.
  """
  def teacher_fixture(attrs \\ %{}) do
    {:ok, teacher} =
      attrs
      |> Enum.into(%{
        school_id: maybe_gen_school_id(attrs),
        name: "some full name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_teacher()

    teacher
  end

  # generator helpers

  def maybe_gen_school_id(%{school_id: school_id} = _attrs), do: school_id
  def maybe_gen_school_id(_attrs), do: school_fixture().id

  def maybe_gen_cycle_id(%{cycle_id: cycle_id} = _attrs), do: cycle_id
  def maybe_gen_cycle_id(_attrs), do: cycle_fixture().id

  def maybe_gen_student_id(%{student_id: student_id} = _attrs), do: student_id
  def maybe_gen_student_id(_attrs), do: student_fixture().id
end
