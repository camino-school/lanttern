defmodule Lanttern.AttachmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Attachments` context.
  """

  @doc """
  Generate a attachment.
  """
  def attachment_fixture(attrs \\ %{}) do
    {:ok, attachment} =
      attrs
      |> Enum.into(%{
        name: "some name",
        link: "https://some-valid.link",
        owner_id: Lanttern.IdentityFixtures.maybe_gen_profile_id(attrs, foreign_key: :owner_id)
      })
      |> Lanttern.Attachments.create_attachment()

    attachment
  end
end
