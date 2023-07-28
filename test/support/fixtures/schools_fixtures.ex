defmodule Lanttern.SchoolsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Schools` context.
  """

  @doc """
  Generate a student.
  """
  def student_fixture(attrs \\ %{}) do
    {:ok, student} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Lanttern.Schools.create_student()

    student
  end
end
