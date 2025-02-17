defmodule LantternWeb.MomentLive.NotesComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.NotesFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Moment notes" do
    test "display existing note", %{conn: conn, user: user} do
      strand = LearningContextFixtures.strand_fixture()
      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      note =
        NotesFixtures.moment_note_fixture(user, moment.id, %{
          "description" => "moment note desc abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/moment/#{moment.id}/notes")
      assert view |> has_element?("p", note.description)
    end

    test "create note", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()
      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/moment/#{moment.id}/notes")

      assert view |> has_element?("p", "You don't have any notes for this moment yet")

      view |> element("button", "Add a moment note") |> render_click()

      attrs = %{"description" => "new moment note"}

      assert view
             |> form("#note-form", note: attrs)
             |> render_submit()

      render(view)

      assert view |> has_element?("p", "new moment note")
    end
  end
end
