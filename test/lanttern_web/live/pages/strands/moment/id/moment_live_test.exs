defmodule LantternWeb.MomentLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands/moment"

  setup [:register_and_log_in_teacher]

  describe "Moment details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})

      moment =
        LearningContextFixtures.moment_fixture(%{name: "moment abc", strand_id: strand.id})

      conn = get(conn, "#{@live_view_base_path}/#{moment.id}")

      assert html_response(conn, 200) =~ ~r"<a .+>\s*strand abc\s*<\/a>"
      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*moment abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display moment basic info", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})

      moment =
        LearningContextFixtures.moment_fixture(%{
          name: "moment abc",
          subjects_ids: [subject.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}")

      assert view |> has_element?("h1", moment.name)
      assert view |> has_element?("span", subject.name)
    end

    test "moment tab navigation", %{conn: conn} do
      moment =
        LearningContextFixtures.moment_fixture(%{description: "moment description abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}")

      assert view |> has_element?("p", "moment description abc")

      # assessment tab

      view
      |> element("#moment-nav-tabs a", "Moment assessment")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "No class selected")

      # cards tab

      view
      |> element("#moment-nav-tabs a", "Cards")
      |> render_click()

      assert_patch(view)

      assert view
             |> has_element?("p", "Use cards to add an extra layer of organization to moments")

      # notes tab

      view
      |> element("#moment-nav-tabs a", "Notes")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Add a moment note")

      # back to details tab

      view
      |> element("#moment-nav-tabs a", "Overview")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("p", "moment description abc")
    end
  end

  describe "Moment management" do
    test "edit moment", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      strand = LearningContextFixtures.strand_fixture(%{subjects_ids: [subject.id]})

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "moment abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?is_editing=true")

      assert view
             |> has_element?("h2", "Edit moment")

      # add subject
      view
      |> element("#moment-form #moment_subject_id")
      |> render_change(%{"moment" => %{"subject_id" => subject.id}})

      # submit form with valid field
      view
      |> element("#moment-form")
      |> render_submit(%{
        "moment" => %{
          "name" => "moment name xyz"
        }
      })

      assert_patch(view, "#{@live_view_base_path}/#{moment.id}")

      assert view |> has_element?("h1", "moment name xyz")
      assert view |> has_element?("span", subject.name)
    end

    test "delete moment", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}")

      view
      |> element("button#remove-moment-#{moment.id}")
      |> render_click()

      assert_redirect(view, "/strands/#{moment.strand_id}/moments")
    end
  end
end
