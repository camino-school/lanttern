defmodule LantternWeb.StrandsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path "/strands"

  setup [:register_and_log_in_teacher]

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
end
