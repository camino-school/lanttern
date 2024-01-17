defmodule LantternWeb.StrandLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_user]

  describe "Strand details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      conn = get(conn, "#{@live_view_base_path}/#{strand.id}")

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*strand abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display strand basic info", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture(%{name: "curriculum item abc"})

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "strand abc",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      AssessmentsFixtures.assessment_point_fixture(
        %{curriculum_item_id: curriculum_item.id},
        strand_id: strand.id
      )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("h1", strand.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
      assert view |> has_element?("p", curriculum_item.name)
    end

    test "strand tab navigation", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{description: "strand description abc"})

      _activity =
        LearningContextFixtures.activity_fixture(%{name: "activity abc", strand_id: strand.id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("p", "strand description abc")

      # activities tab

      view
      |> element("#strand-nav-tabs a", "Activities")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("a", "activity abc")

      # assessment tab

      view
      |> element("#strand-nav-tabs a", "Assessment")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Select a class")
      assert view |> has_element?("p", "to view students assessments")

      # notes tab

      view
      |> element("#strand-nav-tabs a", "My notes")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Add a strand note")

      # back to about tab

      view
      |> element("#strand-nav-tabs a", "About")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("p", "strand description abc")
    end
  end

  describe "Strand management" do
    test "edit strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/edit")

      assert view
             |> has_element?("h2", "Edit strand")

      # add subject
      view
      |> element("#strand-form #strand_subject_id")
      |> render_change(%{"strand" => %{"subject_id" => subject.id}})

      # add year
      view
      |> element("#strand-form #strand_year_id")
      |> render_change(%{"strand" => %{"year_id" => year.id}})

      # submit form with valid field
      view
      |> element("#strand-form")
      |> render_submit(%{
        "strand" => %{
          "name" => "strand name xyz"
        }
      })

      assert_patch(view, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("h1", "strand name xyz")
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end

    test "delete strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      view
      |> element("button#remove-strand-#{strand.id}")
      |> render_click()

      assert_redirect(view, "/strands")
    end
  end

  describe "Activity management" do
    alias Lanttern.LearningContext.Activity

    test "create activity", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      strand = LearningContextFixtures.strand_fixture(%{subjects_ids: [subject.id]})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?tab=activities")

      # open create activity overlay
      view |> element("a", "Create new activity") |> render_click()
      assert_patch(view, "#{@live_view_base_path}/#{strand.id}/new_activity")
      assert view |> has_element?("h2", "New activity")

      # add subject
      view
      |> element("#activity-form #activity_subject_id")
      |> render_change(%{"activity" => %{"subject_id" => subject.id}})

      # submit form with valid fields
      view
      |> element("#activity-form")
      |> render_submit(%{
        "activity" => %{
          "strand_id" => strand.id,
          "name" => "activity name abc",
          "description" => "description abc"
        }
      })

      {path, _flash} = assert_redirect(view)

      [_, activity_id] =
        ~r".+\/(\d+)\z"
        |> Regex.run(path)

      activity =
        Activity
        |> Lanttern.Repo.get!(activity_id)
        |> Lanttern.Repo.preload(:subjects)

      assert activity.name == "activity name abc"
      assert activity.subjects == [subject]
    end
  end
end
