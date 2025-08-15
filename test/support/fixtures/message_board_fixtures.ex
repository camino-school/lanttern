defmodule Lanttern.MessageBoardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.MessageBoard` context.
  """

  alias Lanttern.SchoolsFixtures

  import Lanttern.Factory

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        send_to: "school",
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs),
        section_id: insert(:section).id
      })
      |> Lanttern.MessageBoard.create_message()

    message
  end
end
