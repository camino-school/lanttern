defmodule LantternWeb.StrandLive.DetailsTest do
  use LantternWeb.ConnCase

  alias Lanttern.CurriculaFixtures
  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_user]

  describe "Strands live view basic navigation" do
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
          years_ids: [year.id],
          curriculum_items: [%{curriculum_item_id: curriculum_item.id}]
        })

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

      assert view |> has_element?("div", "Assessment TBD")

      # notes tab

      view
      |> element("#strand-nav-tabs a", "My notes")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "Add a strand note")

      # back to about tab

      view
      |> element("#strand-nav-tabs a", "About & Curriculum")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("p", "strand description abc")
    end
  end
end