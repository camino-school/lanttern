defmodule Lanttern.GradingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Grading` context.
  """

  @doc """
  Generate a grade_component.
  """
  def grade_component_fixture(attrs \\ %{}) do
    {:ok, grade_component} =
      attrs
      |> Enum.into(%{
        position: 42,
        weight: 120.5,
        report_card_id: Lanttern.ReportingFixtures.maybe_gen_report_card_id(attrs),
        assessment_point_id: Lanttern.AssessmentsFixtures.maybe_gen_assessment_point_id(attrs),
        subject_id: Lanttern.TaxonomyFixtures.maybe_gen_subject_id(attrs)
      })
      |> Lanttern.Grading.create_grade_component()

    grade_component
  end

  @doc """
  Generate a scale.
  """
  def scale_fixture(attrs \\ %{})

  def scale_fixture(%{type: "ordinal"} = attrs) do
    {:ok, scale} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: "ordinal",
        breakpoints: [0.4, 0.8]
      })
      |> Lanttern.Grading.create_scale()

    scale
  end

  def scale_fixture(attrs) do
    {:ok, scale} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: "numeric",
        start: 0,
        stop: 100
      })
      |> Lanttern.Grading.create_scale()

    scale
  end

  @doc """
  Generate a ordinal_value.
  """
  def ordinal_value_fixture(attrs \\ %{}) do
    scale = scale_fixture()

    {:ok, ordinal_value} =
      attrs
      |> Enum.into(%{
        name: "some name",
        normalized_value: 1,
        scale_id: scale.id,
        bg_color: "#000000",
        text_color: "#ffffff"
      })
      |> Lanttern.Grading.create_ordinal_value()

    ordinal_value
  end

  # generator helpers

  def maybe_gen_scale_id(%{scale_id: scale_id} = _attrs), do: scale_id
  def maybe_gen_scale_id(_attrs), do: scale_fixture().id
end
