defmodule Lanttern.PersonalizationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Personalization` context.
  """

  @doc """
  Generate a profile_view.
  """
  def profile_view_fixture(attrs \\ %{}) do
    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.teacher_profile_fixture().id

    {:ok, profile_view} =
      attrs
      |> Enum.into(%{
        name: "some name",
        profile_id: profile_id
      })
      |> Lanttern.Personalization.create_profile_view()

    profile_view
  end
end
