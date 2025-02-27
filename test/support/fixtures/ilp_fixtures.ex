defmodule Lanttern.ILPFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.ILP` context.
  """

  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a ilp_template.
  """
  def ilp_template_fixture(attrs \\ %{}) do
    {:ok, ilp_template} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> Lanttern.ILP.create_ilp_template()

    ilp_template
  end

  @doc """
  Generate a ilp_section.
  """
  def ilp_section_fixture(attrs \\ %{}) do
    {:ok, ilp_section} =
      attrs
      |> Enum.into(%{
        name: "some name",
        position: 42,
        template_id: maybe_gen_template_id(attrs)
      })
      |> Lanttern.ILP.create_ilp_section()

    ilp_section
  end

  @doc """
  Generate a ilp_component.
  """
  def ilp_component_fixture(attrs \\ %{}) do
    {:ok, ilp_component} =
      attrs
      |> maybe_inject_template_id()
      |> maybe_inject_section_id()
      |> Enum.into(%{
        name: "some name",
        position: 42
      })
      |> Lanttern.ILP.create_ilp_component()

    ilp_component
  end

  @doc """
  Generate a student_ilp.
  """
  def student_ilp_fixture(attrs \\ %{}) do
    {:ok, student_ilp} =
      attrs
      |> maybe_inject_school_id()
      |> maybe_inject_cycle_id()
      |> maybe_inject_template_id()
      |> maybe_inject_student_id()
      |> Enum.into(%{
        teacher_notes: "some note"
      })
      |> Lanttern.ILP.create_student_ilp()

    student_ilp
  end

  # generator helpers

  def maybe_gen_template_id(%{template_id: template_id} = _attrs), do: template_id
  def maybe_gen_template_id(_attrs), do: ilp_template_fixture().id

  # helpers

  defp maybe_inject_school_id(%{school_id: _} = attrs), do: attrs

  defp maybe_inject_school_id(attrs) do
    attrs
    |> Map.put(:school_id, SchoolsFixtures.school_fixture().id)
  end

  defp maybe_inject_cycle_id(%{cycle_id: _} = attrs), do: attrs

  defp maybe_inject_cycle_id(attrs) do
    attrs
    |> Map.put(:cycle_id, SchoolsFixtures.cycle_fixture(%{school_id: attrs.school_id}).id)
  end

  defp maybe_inject_student_id(%{student_id: _} = attrs), do: attrs

  defp maybe_inject_student_id(attrs) do
    attrs
    |> Map.put(:student_id, SchoolsFixtures.student_fixture(%{school_id: attrs.school_id}).id)
  end

  defp maybe_inject_template_id(%{template_id: _} = attrs), do: attrs

  defp maybe_inject_template_id(%{school_id: school_id} = attrs) do
    attrs
    |> Map.put(:template_id, ilp_template_fixture(%{school_id: school_id}).id)
  end

  defp maybe_inject_template_id(attrs) do
    attrs
    |> Map.put(:template_id, ilp_template_fixture().id)
  end

  defp maybe_inject_section_id(%{section_id: _} = attrs), do: attrs

  defp maybe_inject_section_id(attrs) do
    attrs
    |> Map.put(:section_id, ilp_section_fixture(template_id: attrs.template_id).id)
  end
end
