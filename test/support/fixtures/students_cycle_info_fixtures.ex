defmodule Lanttern.StudentsCycleInfoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.StudentsCycleInfo` context.
  """

  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a student_cycle_info.
  """
  def student_cycle_info_fixture(attrs \\ %{}) do
    {:ok, student_cycle_info} =
      attrs
      |> maybe_inject_school_id()
      |> maybe_inject_student_id()
      |> maybe_inject_cycle_id()
      |> Enum.into(%{
        shared_info: "some shared_info",
        profile_picture: "some profile_picture",
        school_info: "some school_info"
      })
      |> Lanttern.StudentsCycleInfo.create_student_cycle_info()

    student_cycle_info
  end

  # helpers

  defp maybe_inject_school_id(%{school_id: _} = attrs), do: attrs

  defp maybe_inject_school_id(attrs) do
    attrs
    |> Map.put(:school_id, SchoolsFixtures.school_fixture().id)
  end

  defp maybe_inject_student_id(%{student_id: _} = attrs), do: attrs

  defp maybe_inject_student_id(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:student_id, SchoolsFixtures.student_fixture(%{school_id: school_id}).id)
  end

  defp maybe_inject_cycle_id(%{cycle_id: _} = attrs), do: attrs

  defp maybe_inject_cycle_id(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:cycle_id, SchoolsFixtures.cycle_fixture(%{school_id: school_id}).id)
  end
end
