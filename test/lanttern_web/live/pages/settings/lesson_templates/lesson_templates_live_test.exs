defmodule LantternWeb.LessonTemplatesLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Repo

  @live_view_path "/settings/lesson_templates"

  setup [:register_and_log_in_staff_member]

  describe "Lesson templates live view" do
    test "lesson templates are listed", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:lesson_template, %{school: school, name: "Template Alpha"})
      insert(:lesson_template, %{school: school, name: "Template Beta"})

      conn
      |> visit(@live_view_path)
      |> assert_has("#lesson-templates-list", text: "Template Alpha")
      |> assert_has("#lesson-templates-list", text: "Template Beta")
    end

    test "lesson template detail is displayed correctly", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      lesson_template =
        insert(:lesson_template,
          school: school,
          name: "Template Detail",
          about: "This template is for science lessons",
          template: "## Lesson structure\n\n1. Introduction\n2. Main activity"
        )

      insert(:lesson_template, %{
        school: school,
        name: "Other Template",
        about: "Different content"
      })

      conn
      |> visit("#{@live_view_path}/#{lesson_template.id}")
      |> assert_has("#lesson-templates-list", text: "Template Detail")
      |> assert_has("#lesson-templates-list", text: "About")
      |> assert_has("#lesson-templates-list", text: "This template is for science lessons")
      |> assert_has("#lesson-templates-list", text: "Template")
      |> assert_has("#lesson-templates-list", text: "Lesson structure")
      |> refute_has("#lesson-templates-list", text: "Different content")
    end

    test "create lesson template", context do
      %{conn: conn} = set_user_permissions(["content_management"], context)

      session =
        conn
        |> visit(@live_view_path)
        |> click_button("New template")
        |> within("#lesson-template-form-overlay", fn conn ->
          conn
          |> fill_in("Template name", with: "New template name")
          |> click_button("Save")
        end)

      # get created lesson template id
      lesson_template =
        Repo.get_by(Lanttern.LessonTemplates.LessonTemplate, name: "New template name")

      session
      |> assert_path("#{@live_view_path}/#{lesson_template.id}")
      |> assert_has("#lesson-templates-list", text: "New template name")
      |> assert_has("#lesson-templates-list", text: "Edit")
      |> assert_has("#lesson-templates-list button[phx-click=\"edit_about\"]", text: "Add")
    end

    test "edit lesson template", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)
      lesson_template = insert(:lesson_template, %{school: school, name: "Old name"})

      conn
      |> visit("#{@live_view_path}/#{lesson_template.id}")
      |> click_button("#lesson-templates-list button[phx-click=\"edit_lesson_template\"]", "Edit")
      |> within("#lesson-template-form-overlay", fn conn ->
        conn
        |> fill_in("Template name", with: "Updated template name")
        |> click_button("Save")
      end)
      |> assert_has("#lesson-templates-list", text: "Updated template name")
      |> assert_has("#lesson-templates-list", text: "Edit")
    end

    test "delete lesson template", context do
      %{conn: conn, user: user} = set_user_permissions(["content_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)
      lesson_template = insert(:lesson_template, %{school: school, name: "Template to delete"})

      conn
      |> visit("#{@live_view_path}/#{lesson_template.id}")
      |> click_button("#lesson-templates-list button[phx-click=\"edit_lesson_template\"]", "Edit")
      |> click_button("#lesson-template-form-overlay button", "Delete")
      |> refute_has("#lesson-templates-list", text: "Template to delete")
    end
  end
end
