defmodule LantternWeb.StrandsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path "/strands"

  setup [:register_and_log_in_user]

  describe "Strands live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Strands\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list strands and navigate to detail", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "strand abc",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", strand.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)

      view
      |> element("a", strand.name)
      |> render_click()

      assert_redirect(view, "#{@live_view_path}/#{strand.id}")
    end
  end

  describe "Strand management" do
    alias Lanttern.LearningContext.Strand

    test "create strand", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      {:ok, view, _html} = live(conn, @live_view_path)

      # open create strand overlay
      view |> element("button", "Create new strand") |> render_click()
      assert view |> has_element?("h2", "New strand")

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
          "name" => "strand name abc",
          "description" => "description abc"
        }
      })

      {path, _flash} = assert_redirect(view)

      [_, strand_id] =
        ~r".+\/(\d+)\z"
        |> Regex.run(path)

      strand =
        Strand
        |> Lanttern.Repo.get!(strand_id)
        |> Lanttern.Repo.preload([:subjects, :years])

      assert strand.name == "strand name abc"
      assert strand.subjects == [subject]
      assert strand.years == [year]
    end
  end
end
