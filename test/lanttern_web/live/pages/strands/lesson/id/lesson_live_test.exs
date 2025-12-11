defmodule LantternWeb.LessonLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_base_path "/strands/lesson"

  setup [:register_and_log_in_staff_member]

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
end
