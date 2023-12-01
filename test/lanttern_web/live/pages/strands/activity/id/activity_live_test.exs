defmodule LantternWeb.ActivityLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands/activity"

  setup [:register_and_log_in_user]

  describe "Activity details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})

      activity =
        LearningContextFixtures.activity_fixture(%{name: "activity abc", strand_id: strand.id})

      conn = get(conn, "#{@live_view_base_path}/#{activity.id}")

      assert html_response(conn, 200) =~ ~r"<a .+>\s*strand abc\s*<\/a>"
      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*activity abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display activity basic info", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})

      activity =
        LearningContextFixtures.activity_fixture(%{
          name: "activity abc",
          subjects_ids: [subject.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{activity.id}")

      assert view |> has_element?("h1", activity.name)
      assert view |> has_element?("span", subject.name)
    end

    test "activity tab navigation", %{conn: conn} do
      activity =
        LearningContextFixtures.activity_fixture(%{description: "activity description abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{activity.id}")

      assert view |> has_element?("p", "activity description abc")

      # assessment tab

      view
      |> element("#activity-nav-tabs a", "Assessment")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Select a class")
      assert view |> has_element?("p", "to assess students")

      # notes tab

      view
      |> element("#activity-nav-tabs a", "My notes")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Add an activity note")

      # back to details tab

      view
      |> element("#activity-nav-tabs a", "Details & Curriculum")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("p", "activity description abc")
    end
  end

  describe "Activity management" do
    test "edit activity", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      strand = LearningContextFixtures.strand_fixture(%{subjects_ids: [subject.id]})

      activity =
        LearningContextFixtures.activity_fixture(%{strand_id: strand.id, name: "activity abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{activity.id}/edit")

      assert view
             |> has_element?("h2", "Edit activity")

      # add subject
      view
      |> element("#activity-form #activity_subject_id")
      |> render_change(%{"activity" => %{"subject_id" => subject.id}})

      # submit form with valid field
      view
      |> element("#activity-form")
      |> render_submit(%{
        "activity" => %{
          "name" => "activity name xyz"
        }
      })

      assert_patch(view, "#{@live_view_base_path}/#{activity.id}")

      assert view |> has_element?("h1", "activity name xyz")
      assert view |> has_element?("span", subject.name)
    end

    test "delete activity", %{conn: conn} do
      activity = LearningContextFixtures.activity_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{activity.id}")

      view
      |> element("button#remove-activity-#{activity.id}")
      |> render_click()

      assert_redirect(view, "/strands/#{activity.strand_id}?tab=activities")
    end
  end
end
