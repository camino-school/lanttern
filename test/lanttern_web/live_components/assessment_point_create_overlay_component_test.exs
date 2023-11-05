defmodule LantternWeb.AssessmentPointCreateOverlayComponentTest do
  use LantternWeb.ConnCase

  @assessment_points_path "/assessment_points"
  @overlay_selector "#create-assessment-point-overlay"
  @form_selector "#create-assessment-point-form"

  setup :register_and_log_in_user

  describe "Create assessment point form in assessment points live view" do
    test "form shows in live view", %{conn: conn} do
      {:ok, view, _html} = live(conn, @assessment_points_path)

      # to-do:
      # after `<.slide_over>` refactor, the HTML is already rendered, just not visible.
      # in the future we can reimplement client-side interactions tests (using Wallaby, maybe?)

      # # confirms overlay is not rendered
      # refute view
      #        |> element("h2", "Create assessment point")
      #        |> has_element?()

      # # click button to render
      # view
      # |> element("button", "Create assessment point")
      # |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#{@overlay_selector} h2", "Create assessment point")
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
          name: "class 1",
          students_ids: [std_1.id, std_2.id, std_3.id]
        })

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # select class
      view
      |> element("#{@overlay_selector} select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class.id}})

      # assert class and students badges are rendered
      assert view
             |> element("#{@overlay_selector} #class-badge-#{class.id}", class.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1.id}", std_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2.id}", std_2.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_3.id}", std_3.name)
             |> has_element?()

      # remove class should not affect students
      view
      |> element("#{@overlay_selector} #class-badge-#{class.id} button")
      |> render_click()

      refute view
             |> element("#{@overlay_selector} #class-badge-#{class.id}", class.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1.id}", std_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2.id}", std_2.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_3.id}", std_3.name)
             |> has_element?()

      # remove student should not affect other students
      view
      |> element("#{@overlay_selector} #student-badge-#{std_3.id} button")
      |> render_click()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1.id}", std_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2.id}", std_2.name)
             |> has_element?()

      refute view
             |> element("#{@overlay_selector} #student-badge-#{std_3.id}", std_3.name)
             |> has_element?()
    end

    test "selecting a class merges the selected class students with already selected students", %{
      conn: conn
    } do
      std_1_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1-1"})
      std_1_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1-2"})

      std_2_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 2-1"})
      std_2_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 2-2"})

      class_1 =
        Lanttern.SchoolsFixtures.class_fixture(%{
          name: "class 1",
          students_ids: [std_1_1.id, std_1_2.id]
        })

      class_2 =
        Lanttern.SchoolsFixtures.class_fixture(%{
          name: "class 2",
          students_ids: [std_2_1.id, std_2_2.id]
        })

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # select class 1 and assert class and students badges are rendered
      view
      |> element("#{@overlay_selector} select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class_1.id}})

      assert view
             |> element("#{@overlay_selector} #class-badge-#{class_1.id}", class_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1_1.id}", std_1_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1_2.id}", std_1_2.name)
             |> has_element?()

      # select class 2 and assert all class and students badges are rendered
      view
      |> element("#{@overlay_selector} select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class_2.id}})

      assert view
             |> element("#{@overlay_selector} #class-badge-#{class_1.id}", class_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1_1.id}", std_1_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1_2.id}", std_1_2.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #class-badge-#{class_2.id}", class_2.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2_1.id}", std_2_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2_2.id}", std_2_2.name)
             |> has_element?()
    end

    test "selecting a student create students badges, which can be removed", %{
      conn: conn
    } do
      std = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1"})

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # select student
      view
      |> element("#{@overlay_selector} select", "Select students")
      |> render_change(%{"assessment_point" => %{"student_id" => std.id}})

      # assert student badge is rendered
      assert view
             |> element("#{@overlay_selector} #student-badge-#{std.id}", std.name)
             |> has_element?()

      # remove student
      view
      |> element("#{@overlay_selector} #student-badge-#{std.id} button")
      |> render_click()

      refute view
             |> element("#{@overlay_selector} #student-badge-#{std.id}", std.name)
             |> has_element?()
    end

    test "selecting a student merges the selected student with already selected students", %{
      conn: conn
    } do
      std_1 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 1"})
      std_2 = Lanttern.SchoolsFixtures.student_fixture(%{name: "std 2"})

      {:ok, view, _html} = live(conn, @assessment_points_path)

      # select student 1 and assert badge is rendered
      view
      |> element("#{@overlay_selector} select", "Select students")
      |> render_change(%{"assessment_point" => %{"student_id" => std_1.id}})

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1.id}", std_1.name)
             |> has_element?()

      # select student 2 and assert all students badges are rendered
      view
      |> element("#{@overlay_selector} select", "Select students")
      |> render_change(%{"assessment_point" => %{"student_id" => std_2.id}})

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_1.id}", std_1.name)
             |> has_element?()

      assert view
             |> element("#{@overlay_selector} #student-badge-#{std_2.id}", std_2.name)
             |> has_element?()
    end

    test "submit valid form saves and redirect", %{conn: conn} do
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
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

      # select class
      view
      |> element("#{@overlay_selector} select", "Select classes")
      |> render_change(%{"assessment_point" => %{"class_id" => class.id}})

      # submit with extra info
      view
      |> element("#{@overlay_selector} #{@form_selector}")
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
               Lanttern.Assessments.get_assessment_point!(id, preloads: [:entries, :classes])

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

      # submit
      view
      |> element("#{@overlay_selector} #{@form_selector}")
      |> render_submit()

      assert_raise ArgumentError, fn ->
        assert_redirect(view)
      end
    end
  end
end
