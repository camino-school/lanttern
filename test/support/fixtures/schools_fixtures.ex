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
        name: Faker.Lorem.sentence(2..5)
      })
      |> Lanttern.Schools.create_school()

    school
  end

  @doc """
  Generate a class.
  """
  def class_fixture(attrs \\ %{}) do
    {:ok, class} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(2..5)
      })
      |> Lanttern.Schools.create_class()

    class
  end

  @doc """
  Generate a student.
  """
  def student_fixture(attrs \\ %{})

  def student_fixture(%{school_id: _school_id} = attrs) do
    {:ok, student} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(2..5)
      })
      |> Lanttern.Schools.create_student()

    student
  end

  def student_fixture(attrs) do
    school = school_fixture()

    {:ok, student} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(2..5),
        school_id: school.id
      })
      |> Lanttern.Schools.create_student()

    student
  end

  @doc """
  Generate a teacher.
  """
  def teacher_fixture(attrs \\ %{})

  def teacher_fixture(%{school_id: _school_id} = attrs) do
    {:ok, teacher} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(2..5)
      })
      |> Lanttern.Schools.create_teacher()

    teacher
  end

  def teacher_fixture(attrs) do
    school = school_fixture()

    {:ok, teacher} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(2..5),
        school_id: school.id
      })
      |> Lanttern.Schools.create_teacher()

    teacher
  end
end
