defmodule LantternWeb.LessonTagsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import Phoenix.LiveViewTest
  import PhoenixTest

  alias Lanttern.Repo

  @live_view_path "/settings/lesson_tags"

  setup [:register_and_log_in_staff_member]

  describe "Lesson tags live view" do
    test "lesson tags are listed", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:lesson_tag, %{
        school: school,
        name: "Tag Alpha",
        bg_color: "#ff0000",
        text_color: "#ffffff"
      })

      insert(:lesson_tag, %{
        school: school,
        name: "Tag Beta",
        bg_color: "#00ff00",
        text_color: "#000000"
      })

      conn
      |> visit(@live_view_path)
      |> assert_has("#lesson-tags-list", text: "Tag Alpha")
      |> assert_has("#lesson-tags-list", text: "Tag Beta")
    end

    test "lesson tag detail is displayed correctly when expanded", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      lesson_tag =
        insert(:lesson_tag,
          school: school,
          name: "Detailed Tag",
          bg_color: "#aabbcc",
          text_color: "#112233",
          agent_description: "This tag is for science-related lessons"
        )

      insert(:lesson_tag, %{
        school: school,
        name: "Other Tag",
        bg_color: "#000000",
        text_color: "#ffffff",
        agent_description: "Different description"
      })

      conn
      |> visit("#{@live_view_path}/#{lesson_tag.id}")
      |> assert_has("#lesson-tags-list", text: "Detailed Tag")
      |> assert_has("#lesson-tags-list", text: "Agent description")
      |> assert_has("#lesson-tags-list", text: "This tag is for science-related lessons")
      |> refute_has("#lesson-tags-list", text: "Different description")
    end

    test "create lesson tag", context do
      %{conn: conn} = set_user_permissions(["content_management"], context)

      session =
        conn
        |> visit(@live_view_path)
        |> click_button("New tag")
        |> within("#lesson-tag-form-overlay", fn conn ->
          conn
          |> fill_in("Lesson tag name", with: "New tag name")
          |> fill_in("Background color (hex)", with: "#ff5500")
          |> fill_in("Text color (hex)", with: "#ffffff")
          |> click_button("Save")
        end)

      lesson_tag = Repo.get_by(Lanttern.Lessons.Tag, name: "New tag name")

      session
      |> assert_path("#{@live_view_path}/#{lesson_tag.id}")
      |> assert_has("#lesson-tags-list", text: "New tag name")
      |> assert_has("#lesson-tags-list", text: "Edit")
    end

    test "edit lesson tag", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      lesson_tag =
        insert(:lesson_tag, %{
          school: school,
          name: "Old name",
          bg_color: "#aabbcc",
          text_color: "#112233"
        })

      conn
      |> visit("#{@live_view_path}/#{lesson_tag.id}")
      |> click_button("#lesson-tags-list button[phx-click=\"edit_lesson_tag\"]", "Edit")
      |> within("#lesson-tag-form-overlay", fn conn ->
        conn
        |> fill_in("Lesson tag name", with: "Updated tag name")
        |> click_button("Save")
      end)
      |> assert_has("#lesson-tags-list", text: "Updated tag name")
      |> assert_has("#lesson-tags-list", text: "Edit")
    end

    test "delete lesson tag", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      lesson_tag =
        insert(:lesson_tag, %{
          school: school,
          name: "Tag to delete",
          bg_color: "#aabbcc",
          text_color: "#112233"
        })

      conn
      |> visit("#{@live_view_path}/#{lesson_tag.id}")
      |> click_button("#lesson-tags-list button[phx-click=\"edit_lesson_tag\"]", "Edit")
      |> click_button("#lesson-tag-form-overlay button", "Delete")
      |> refute_has("#lesson-tags-list", text: "Tag to delete")
    end

    test "reorders lesson tags via sortable_update event", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      tag1 =
        insert(:lesson_tag, %{
          school: school,
          name: "Tag 1",
          bg_color: "#ff0000",
          text_color: "#ffffff",
          position: 0
        })

      tag2 =
        insert(:lesson_tag, %{
          school: school,
          name: "Tag 2",
          bg_color: "#00ff00",
          text_color: "#000000",
          position: 1
        })

      tag3 =
        insert(:lesson_tag, %{
          school: school,
          name: "Tag 3",
          bg_color: "#0000ff",
          text_color: "#ffffff",
          position: 2
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      # Simulate drag: move Tag 3 (index 2) to first position (index 0)
      render_hook(view, "sortable_update", %{"oldIndex" => 2, "newIndex" => 0})

      # Verify positions are persisted: expected order [tag3, tag1, tag2]
      assert Repo.get!(Lanttern.Lessons.Tag, tag3.id).position == 0
      assert Repo.get!(Lanttern.Lessons.Tag, tag1.id).position == 1
      assert Repo.get!(Lanttern.Lessons.Tag, tag2.id).position == 2
    end

    test "shows empty state when no lesson tags exist", context do
      %{conn: conn} = set_user_permissions(["content_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("p", text: "No lesson tags created yet")
    end
  end
end
