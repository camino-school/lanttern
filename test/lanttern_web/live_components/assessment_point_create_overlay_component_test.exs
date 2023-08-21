defmodule LantternWeb.AssessmentPointCreateOverlayComponentTest do
  use LantternWeb.ConnCase

  @assessment_points_path "/assessment_points"

  describe "Create assessment point form in assessment points live view" do
    test "form shows in live view", %{conn: conn} do
      {:ok, view, _html} = live(conn, @assessment_points_path)

      # confirms overlay is not rendered
      refute view
             |> element("h2", "Create assessment point")
             |> has_element?()

      # click button to render
      view
      |> element("button", "Create assessment point")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("h2", "Create assessment point")
             |> render() =~ "Create assessment point"
    end

    test "selecting a class create class and class students badges, which can be removed", %{
      conn: conn
    } do
      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 2"})
      std_3 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 3"})

      class =
        Lanttern.SchoolsFixtures.class_fixture(%{
          name: "some class",
          students_ids: [std_1.id, std_2.id, std_3.id]
        })

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # open overlay
      view
      |> element("button", "Create assessment point")
      |> render_click()

      # select class
      view
      |> element("select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class.id}})

      # assert class and students badges are rendered
      assert view
             |> element("span.rounded-sm", class.name)
             |> render() =~ class.name

      assert view
             |> element("span.rounded-sm", std_1.name)
             |> render() =~ std_1.name

      assert view
             |> element("span.rounded-sm", std_2.name)
             |> render() =~ std_2.name

      assert view
             |> element("span.rounded-sm", std_3.name)
             |> render() =~ std_3.name

      # delete class
      view
      |> element("#class-badge-#{class.id} button")
      |> render_click()

      refute view
             |> element("span.rounded-sm", class.name)
             |> has_element?()

      # delete std_3
      view
      |> element("#student-badge-#{std_3.id} button")
      |> render_click()

      refute view
             |> element("span.rounded-md", std_3.name)
             |> has_element?()
    end

    test "submit valid form saves and redirect", %{conn: conn} do
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()
      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 2"})
      std_3 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 3"})

      class =
        Lanttern.SchoolsFixtures.class_fixture(%{
          name: "some class",
          students_ids: [std_1.id, std_2.id, std_3.id]
        })

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # open overlay
      view
      |> element("button", "Create assessment point")
      |> render_click()

      # select class
      view
      |> element("select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class.id}})

      # submit with extra info
      view
      |> element("#create-assessment-point-form")
      |> render_submit(%{
        "assessment_point" => %{
          "name" => "some name",
          "curriculum_item_id" => curriculum_item.id,
          "scale_id" => scale.id
        }
      })

      {path, flash} = assert_redirect(view)
      assert %{"info" => "Assessment point \"some name\" created!"} = flash
      id = path |> Path.basename() |> String.to_integer()

      # assert created assessment point
      assert assessment_point =
               Lanttern.Assessments.get_assessment_point!(id, [:entries, :classes])

      assert assessment_point.name == "some name"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id
      [ap_class] = assessment_point.classes
      assert ap_class.id == class.id
      assert length(assessment_point.entries) == 3
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == std_1.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == std_2.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == std_3.id end)
    end

    test "submit invalid form prevents save/redirect", %{conn: conn} do
      {:ok, view, _html} = live(conn, @assessment_points_path)

      # open overlay
      view
      |> element("button", "Create assessment point")
      |> render_click()

      # submit
      view
      |> element("#create-assessment-point-form")
      |> render_submit()

      assert_raise ArgumentError, fn ->
        assert_redirect(view)
      end
    end
  end
end
