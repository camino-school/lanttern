defmodule LantternWeb.StrandLive.DetailsTabs.NotesTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.PersonalizationFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_user]

  describe "Strands notes" do
    test "display existing strand and activities note", %{conn: conn, user: user} do
      strand = LearningContextFixtures.strand_fixture()

      note =
        PersonalizationFixtures.strand_note_fixture(user, strand.id, %{
          "description" => "strand note desc abc"
        })

      activity_1 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 1})

      activity_note_1 =
        PersonalizationFixtures.activity_note_fixture(user, activity_1.id, %{
          "description" => "activity 1 note desc abc"
        })

      activity_2 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 2})

      activity_note_2 =
        PersonalizationFixtures.activity_note_fixture(user, activity_2.id, %{
          "description" => "activity 2 note desc abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?tab=notes")
      assert view |> has_element?("p", note.description)
      assert view |> has_element?("a", activity_1.name)
      assert view |> has_element?("p", activity_note_1.description)
      assert view |> has_element?("a", activity_2.name)
      assert view |> has_element?("p", activity_note_2.description)
    end

    test "create note", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?tab=notes")

      assert view |> has_element?("p", "You don't have any notes for this strand yet")

      view |> element("button", "Add a strand note") |> render_click()

      attrs = %{"description" => "new strand note"}

      assert view
             |> form("#strand-note-form", note: attrs)
             |> render_submit()

      render(view)

      assert view |> has_element?("p", "new strand note")
    end
  end
end
