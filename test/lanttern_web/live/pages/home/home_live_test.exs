defmodule LantternWeb.HomeLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  describe "Home live view basic navigation as Student" do
    setup [:register_and_log_in_student]

    test "displays message board and opens message overlay", ctx do
      school = ctx.user.current_profile.student.school
      section = insert(:section, %{school: school})
      message = insert(:message, %{school: school, section: section})

      ctx.conn
      |> visit("/student")
      |> assert_has("h3", text: message.section.name)
      |> assert_has("h3", text: message.name)
      |> click_button("span[phx-click='card_lookout']", "Find out more")
      |> tap(fn %{current_path: path} -> assert path == "/student?message=#{message.id}" end)
      |> assert_has("#card-message-overlay-#{message.id}")
      |> assert_has("h1", text: message.name)
      |> assert_has("p", text: message.description)
    end
  end

  describe "Home live view basic navigation as Guardian" do
    setup [:register_and_log_in_guardian]

    test "displays message board and opens message overlay", ctx do
      school = ctx.user.current_profile.guardian_of_student.school
      section = insert(:section, %{school: school})
      message = insert(:message, %{section: section, school: school})

      ctx.conn
      |> visit("/guardian")
      |> assert_has("h3", text: message.section.name)
      |> assert_has("h3", text: message.name)
      |> click_button("span[phx-click='card_lookout']", "Find out more")
      |> tap(fn %{current_path: path} -> assert path == "/guardian?message=#{message.id}" end)
      |> assert_has("#card-message-overlay-#{message.id}")
      |> assert_has("h1", text: message.name)
      |> assert_has("p", text: message.description)
    end
  end
end
