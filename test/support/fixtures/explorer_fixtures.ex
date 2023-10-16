defmodule Lanttern.ExplorerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Explorer` context.
  """

  @doc """
  Generate a assessment_points_filter_view.
  """
  def assessment_points_filter_view_fixture(attrs \\ %{}) do
    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.teacher_profile_fixture().id

    {:ok, assessment_points_filter_view} =
      attrs
      |> Enum.into(%{
        name: "some name",
        profile_id: profile_id
      })
      |> Lanttern.Explorer.create_assessment_points_filter_view()

    assessment_points_filter_view
  end
end
