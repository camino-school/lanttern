defmodule LantternWeb.StrandOverviewLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Strand overview live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      conn = get(conn, "#{@live_view_base_path}/#{strand.id}/overview")

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

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/overview")

      assert view |> has_element?("h1", strand.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end
  end

  describe "Strand curriculum items management" do
    test "displays existing curriculum items", %{conn: conn} do
      strand = insert(:strand)
      sci = insert(:strand_curriculum_item, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/overview")
      |> assert_has("p", text: sci.curriculum_item.name)
    end

    test "adds a curriculum item via search modal", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      strand = insert(:strand)
      curriculum_item = insert(:curriculum_item, school_id: school_id, name: "New CI xyz")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/overview")
      |> click_button("#new-curriculum-item-button", "New")
      |> unwrap(fn view ->
        view
        |> element("#curriculum-item-search")
        |> render_hook("autocomplete_result_select", %{"id" => to_string(curriculum_item.id)})
      end)
      |> assert_has("p", text: "New CI xyz")
    end

    test "removes a curriculum item", %{conn: conn} do
      strand = insert(:strand)
      sci = insert(:strand_curriculum_item, strand: strand)
      curriculum_item_name = sci.curriculum_item.name

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/overview")
      |> assert_has("p", text: curriculum_item_name)
      |> click_button("Remove")
      |> refute_has("p", text: curriculum_item_name)
    end
  end

  describe "Strand management" do
    test "edit strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}/#{strand.id}/overview?is_editing=true")

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

      assert_patch(view, "#{@live_view_base_path}/#{strand.id}/overview")

      assert view |> has_element?("h1", "strand name xyz")
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end

    test "delete strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/overview")

      view
      |> element("button#remove-strand-#{strand.id}")
      |> render_click()

      assert_redirect(view, "/strands")
    end
  end
end
