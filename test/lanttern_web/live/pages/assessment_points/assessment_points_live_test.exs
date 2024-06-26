defmodule LantternWeb.AssessmentPointsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @live_view_path "/assessment_points"
  @slider_id "assessment-points-explorer-slider"

  setup [:register_and_log_in_root_admin, :register_and_log_in_teacher]

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

      scale = Lanttern.GradingFixtures.scale_fixture()

      ast_1 = assessment_point_fixture(%{name: "Assessment AAA", scale_id: scale.id})
      ast_2 = assessment_point_fixture(%{name: "Assessment BBB", scale_id: scale.id})
      ast_3 = assessment_point_fixture(%{name: "Assessment CCC", scale_id: scale.id})

      assessment_point_entry_fixture(%{
        student_id: std_1.id,
        assessment_point_id: ast_1.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_2.id,
        assessment_point_id: ast_2.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_3.id,
        assessment_point_id: ast_3.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

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

      scale = Lanttern.GradingFixtures.scale_fixture()

      ast_1 =
        assessment_point_fixture(%{
          scale_id: scale.id,
          name: "Assessment AAA",
          classes_ids: [class.id]
        })

      ast_2 = assessment_point_fixture(%{scale_id: scale.id, name: "Assessment BBB"})

      assessment_point_entry_fixture(%{
        student_id: std_1.id,
        assessment_point_id: ast_1.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_2.id,
        assessment_point_id: ast_2.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_1.id}']",
               ast_1.name
             )

      assert view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_2.id}']",
               ast_2.name
             )

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

      assert view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_1.id}']",
               ast_1.name
             )

      refute view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_2.id}']",
               ast_2.name
             )

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

      scale = Lanttern.GradingFixtures.scale_fixture()

      ast_1 =
        assessment_point_fixture(%{
          name: "Assessment AAA",
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      ast_2 = assessment_point_fixture(%{name: "Assessment BBB", scale_id: scale.id})

      assessment_point_entry_fixture(%{
        student_id: std_1.id,
        assessment_point_id: ast_1.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_2.id,
        assessment_point_id: ast_2.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

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

      assert view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_1.id}']",
               ast_1.name
             )

      refute view
             |> has_element?(
               "##{@slider_id} a[href='/assessment_points/#{ast_2.id}']",
               ast_2.name
             )

      assert view |> has_element?("##{@slider_id} div", std_1.name)
      refute view |> has_element?("##{@slider_id} div", std_2.name)
    end

    test "navigation to assessment point details", %{conn: conn} do
      %{id: id, name: name, scale_id: scale_id} =
        assessment_point_fixture(%{name: "not any name"})

      assessment_point_entry_fixture(%{assessment_point_id: id, scale_id: scale_id})

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", name)
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/assessment_points/#{id}"
    end

    test "form shows in live view", %{conn: conn} do
      {:ok, view, _html} = live(conn, @live_view_path)

      # confirms overlay is not rendered
      refute view
             |> element("h2", "Create assessment point")
             |> has_element?()

      # click link to render
      view
      |> element("a", "Create assessment point")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#create-assessment-point-overlay h2", "Create assessment point")
             |> render() =~ "Create assessment point"
    end
  end
end
