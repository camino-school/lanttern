defmodule LantternWeb.AssessmentPointsExplorerLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @live_view_path "/assessment_points/explorer"
  @slider_id "assessment-points-explorer-slider"

  setup :register_and_log_in_user

  describe "Assessment points explorer live view" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Assessment points explorer\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display grid with links for assessment points and students names", %{conn: conn} do
      # expected grid
      #       ast_1 ast_2 ast_3
      # std_1  [x]   [ ]   [ ]
      # std_2  [ ]   [x]   [ ]
      # std_3  [ ]   [ ]   [x]

      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student AAA"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student BBB"})
      std_3 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student CCC"})

      ast_1 = assessment_point_fixture(%{name: "Assessment AAA"})
      ast_2 = assessment_point_fixture(%{name: "Assessment BBB"})
      ast_3 = assessment_point_fixture(%{name: "Assessment CCC"})

      assessment_point_entry_fixture(%{student_id: std_1.id, assessment_point_id: ast_1.id})
      assessment_point_entry_fixture(%{student_id: std_2.id, assessment_point_id: ast_2.id})
      assessment_point_entry_fixture(%{student_id: std_3.id, assessment_point_id: ast_3.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a[href='/assessment_points/#{ast_1.id}']", ast_1.name)
      assert view |> has_element?("a[href='/assessment_points/#{ast_2.id}']", ast_2.name)
      assert view |> has_element?("a[href='/assessment_points/#{ast_3.id}']", ast_3.name)

      assert view |> has_element?("div", std_1.name)
      assert view |> has_element?("div", std_2.name)
      assert view |> has_element?("div", std_3.name)
    end

    test "filter explorer by class", %{conn: conn} do
      # before            | after
      #       ast_1 ast_2 |       ast_1
      # std_1  [x]   [ ]  | std_1  [x]
      # std_2  [ ]   [x]  |

      class = Lanttern.SchoolsFixtures.class_fixture()
      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student AAA"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student BBB"})

      ast_1 = assessment_point_fixture(%{name: "Assessment AAA", classes_ids: [class.id]})
      ast_2 = assessment_point_fixture(%{name: "Assessment BBB"})

      assessment_point_entry_fixture(%{student_id: std_1.id, assessment_point_id: ast_1.id})
      assessment_point_entry_fixture(%{student_id: std_2.id, assessment_point_id: ast_2.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_1.id}']", ast_1.name)
      assert view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_2.id}']", ast_2.name)

      assert view |> has_element?("##{@slider_id} div", std_1.name)
      assert view |> has_element?("##{@slider_id} div", std_2.name)

      # filter results and assert/refute elements
      view
      |> element("#explorer-filters-form")
      |> render_submit(%{
        "classes_ids" => ["#{class.id}"]
      })

      {path, _flash} = assert_redirect(view)

      {:ok, view, _html} = live(conn, path)

      assert view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_1.id}']", ast_1.name)
      refute view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_2.id}']", ast_2.name)

      assert view |> has_element?("##{@slider_id} div", std_1.name)
      refute view |> has_element?("##{@slider_id} div", std_2.name)
    end

    test "filter explorer by subject", %{conn: conn} do
      # before            | after
      #       ast_1 ast_2 |       ast_1
      # std_1  [x]   [ ]  | std_1  [x]
      # std_2  [ ]   [x]  |

      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student AAA"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "Student BBB"})

      subject = Lanttern.TaxonomyFixtures.subject_fixture()

      curriculum_item =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{subjects_ids: [subject.id]})

      ast_1 =
        assessment_point_fixture(%{name: "Assessment AAA", curriculum_item_id: curriculum_item.id})

      ast_2 = assessment_point_fixture(%{name: "Assessment BBB"})

      assessment_point_entry_fixture(%{student_id: std_1.id, assessment_point_id: ast_1.id})
      assessment_point_entry_fixture(%{student_id: std_2.id, assessment_point_id: ast_2.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a[href='/assessment_points/#{ast_1.id}']", ast_1.name)
      assert view |> has_element?("a[href='/assessment_points/#{ast_2.id}']", ast_2.name)

      assert view |> has_element?("div", std_1.name)
      assert view |> has_element?("div", std_2.name)

      # filter results and assert/refute elements
      view
      |> element("#explorer-filters-form")
      |> render_submit(%{
        "subjects_ids" => ["#{subject.id}"]
      })

      {path, _flash} = assert_redirect(view)

      {:ok, view, _html} = live(conn, path)

      assert view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_1.id}']", ast_1.name)
      refute view |> has_element?("##{@slider_id} a[href='/assessment_points/#{ast_2.id}']", ast_2.name)

      assert view |> has_element?("##{@slider_id} div", std_1.name)
      refute view |> has_element?("##{@slider_id} div", std_2.name)
    end

    test "navigation to assessment point details", %{conn: conn} do
      %{id: id, name: name} = assessment_point_fixture(%{name: "not any name"})
      assessment_point_entry_fixture(%{assessment_point_id: id})

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", name)
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/assessment_points/#{id}"
    end
  end
end
