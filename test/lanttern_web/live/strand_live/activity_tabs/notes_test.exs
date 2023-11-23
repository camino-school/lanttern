defmodule LantternWeb.StrandLive.ActivityTabs.NotesTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.PersonalizationFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_user]

  describe "Activity notes" do
    test "display existing note", %{conn: conn, user: user} do
      strand = LearningContextFixtures.strand_fixture()
      activity = LearningContextFixtures.activity_fixture(%{strand_id: strand.id})

      note =
        PersonalizationFixtures.activity_note_fixture(user, activity.id, %{
          "description" => "activity note desc abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/activity/#{activity.id}?tab=notes")
      assert view |> has_element?("p", note.description)
    end

    test "create note", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()
      activity = LearningContextFixtures.activity_fixture(%{strand_id: strand.id})
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/activity/#{activity.id}?tab=notes")

      assert view |> has_element?("p", "You don't have any notes for this activity yet")

      view |> element("button", "Add an activity note") |> render_click()

      attrs = %{"description" => "new activity note"}

      assert view
             |> form("#activity-note-form", note: attrs)
             |> render_submit()

      render(view)

      assert view |> has_element?("p", "new activity note")
    end
  end
end
