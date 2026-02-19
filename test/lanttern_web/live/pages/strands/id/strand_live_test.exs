defmodule LantternWeb.StrandLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

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

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "strand abc",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("h1", strand.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end

    test "strand tab navigation", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{description: "strand description abc"})

      _moment =
        LearningContextFixtures.moment_fixture(%{name: "moment abc", strand_id: strand.id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("p", "strand description abc")
      assert view |> has_element?("button", "moment abc")

      # assessment tab

      view
      |> element("#strand-nav-tabs a", "Assessment")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("button", "No class selected")

      # back to lessons tab

      view
      |> element("#strand-nav-tabs a", "Lessons")
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

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?is_editing=true")

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
end
