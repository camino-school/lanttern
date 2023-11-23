defmodule LantternWeb.StrandLive.DetailsTabs.NotesTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.PersonalizationFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_user]

  describe "Strands notes" do
    test "display existing note", %{conn: conn, user: user} do
      strand = LearningContextFixtures.strand_fixture()

      note =
        PersonalizationFixtures.strand_note_fixture(user, strand.id, %{
          "description" => "strand note desc abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?tab=notes")
      assert view |> has_element?("p", note.description)
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
