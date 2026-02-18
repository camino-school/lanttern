defmodule LantternWeb.StrandLive.NotesComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.LearningContextFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Strands notes" do
    test "display existing strand and moments note", %{conn: conn, user: user} do
      strand = LearningContextFixtures.strand_fixture()

      # note =
      #   NotesFixtures.strand_note_fixture(user, strand.id, %{
      #     "description" => "Outra nota"
      #   })

      note =
        insert(:note, %{
          strand: strand,
          description: "Minha nota",
          author: user.current_profile,
          inserted_at: ~N[2025-05-19 13:00:00]
        })

      insert(:strand_note_relationship, %{
        strand: strand,
        note: note,
        author: user.current_profile
      })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/notes")
      assert view |> has_element?("p", note.description)
      assert render(view) =~ "Created at May 19, 2025, 10:00"
    end

    test "create note", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/notes")

      assert view |> has_element?("p", "You don't have any notes for this strand yet")

      view |> element("button", "Add a strand note") |> render_click()

      attrs = %{"description" => "new strand note"}

      assert view
             |> form("#note-form", note: attrs)
             |> render_submit()

      render(view)

      assert view |> has_element?("p", "new strand note")
    end
  end
end
