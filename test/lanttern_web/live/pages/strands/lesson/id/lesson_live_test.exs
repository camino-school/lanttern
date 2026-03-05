defmodule LantternWeb.LessonLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

  @live_view_base_path "/strands/lesson"

  setup [:register_and_log_in_staff_member]

  describe "AI button visibility" do
    test "AI button is not visible without agents_management permission", %{conn: conn} do
      lesson = insert(:lesson)

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> refute_has("a", text: "Create with AI")
    end

    test "AI button is visible with agents_management permission", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)
      lesson = insert(:lesson)

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> assert_has("a", text: "Create with AI")
    end
  end

  describe "Lesson view" do
    test "view lesson", %{conn: conn} do
      lesson =
        insert(:lesson,
          name: "Lesson abc",
          teacher_notes: "Some teacher notes abc",
          differentiation_notes: "Some diff notes abc"
        )

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> assert_has("h1", text: "Lesson abc")
      |> assert_has("p", text: "Some teacher notes abc")
      |> assert_has("p", text: "Some diff notes abc")
    end

    test "view lesson with tags", %{conn: conn} do
      tag_a = insert(:lesson_tag, name: "Homework", bg_color: "#ff0000", text_color: "#ffffff")
      tag_b = insert(:lesson_tag, name: "Group work", bg_color: "#00ff00", text_color: "#000000")
      lesson = insert(:lesson, name: "Tagged lesson", tags: [tag_a, tag_b])

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> assert_has("h1", text: "Tagged lesson")
      |> assert_has("div", text: "Homework")
      |> assert_has("div", text: "Group work")
    end

    test "publish lesson", %{conn: conn} do
      lesson = insert(:lesson)

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> assert_has("h1 span", text: "(Draft)")
      # add description and publish
      |> click_button("Add lesson content")
      |> fill_in("Lesson description", with: "Some description")
      |> click_button("#lesson-description-form button", "Save")
      |> click_button("Publish")
      |> refute_has("h1 span", text: "(Draft)")
    end
  end

  describe "Linked assessment points" do
    test "link and unlink assessment point to lesson", %{conn: conn} do
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "AP to link",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{lesson.id}")
      |> refute_has("button", text: "Unlink")
      |> click_button("Link an assessment point to this lesson")
      |> click_button("AP to link")
      |> assert_has("button", text: "AP to link")
      |> assert_has("button", text: "Unlink")
      |> click_button("Unlink")
      |> refute_has("button", text: "Unlink")
    end

    test "linking already-linked assessment point to new lesson shows confirmation modal", %{
      conn: conn
    } do
      strand = insert(:strand)
      lesson_a = insert(:lesson, strand: strand, name: "Lesson Alpha")
      lesson_b = insert(:lesson, strand: strand, name: "Lesson Beta")
      moment = insert(:moment, strand: strand)
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "Already linked AP",
        moment_id: moment.id,
        lesson_id: lesson_a.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{lesson_b.id}")
      |> click_button("Link an assessment point to this lesson")
      |> click_button("Already linked AP")
      |> assert_has("h4", text: "Link assessment point")
      |> assert_has("p",
        text:
          "Do you want to unlink it from \"Lesson Alpha\" and link to \"Lesson Beta\" (this lesson)?"
      )
    end
  end
end
