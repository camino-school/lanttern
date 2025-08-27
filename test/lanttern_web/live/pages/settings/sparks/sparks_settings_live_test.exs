defmodule LantternWeb.SparksSettingsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_path "/settings/sparks"

  setup [:register_and_log_in_staff_member]

  describe "SparksSettings live view basic navigation" do
    test "staff member can access sparks settings page and see basic elements", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("h2")
      |> assert_has("a[href*=\"?new=true\"]")
    end
  end

  describe "Tag listing and management" do
    test "lists tags from current user's school with edit links", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)

      school_id = user.current_profile.school_id
      school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)

      tag1 = insert(:student_insight_tag, school: school, name: "Important")
      tag2 = insert(:student_insight_tag, school: school, name: "Urgent")

      # Create tag in different school (should not be shown)
      other_school = insert(:school)
      _other_tag = insert(:student_insight_tag, school: other_school, name: "Other School")

      conn
      |> visit(@live_view_path)
      |> assert_has("#sparks-tags")
      |> assert_has("#tags-#{tag1.id}")
      |> assert_has("#tags-#{tag2.id}")
      |> assert_has("a[href*=\"?tag_id=#{tag2.id}\"]", text: "Edit")
    end
  end

  describe "Tag form workflows" do
    test "user can create a new tag", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)

      conn
      |> visit(@live_view_path)
      |> click_link("Add new tag")
      |> assert_has("#sparks-tag-form-overlay")
      |> assert_has("h2", text: "New Tag")
      |> assert_has("input[name=\"tag[name]\"]")
      |> assert_has("input[name=\"tag[bg_color]\"]")
      |> assert_has("input[name=\"tag[text_color]\"]")
    end

    test "user can edit an existing tag", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)

      school_id = user.current_profile.school_id
      school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)
      tag = insert(:student_insight_tag, school: school, name: "Test Tag", bg_color: "#ff0000")

      conn
      |> visit(@live_view_path <> "?tag_id=#{tag.id}")
      |> assert_has("#sparks-tag-form-overlay")
      |> assert_has("h2", text: "Edit Tag")
      |> assert_has("input[value=\"Test Tag\"]")
      |> assert_has("input[value=\"#ff0000\"]")
      |> assert_has("button", text: "Delete")
    end

    test "invalid tag ID does not show overlay", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)

      conn
      |> visit(@live_view_path <> "?tag_id=999999")
      |> refute_has("#sparks-tag-form-overlay")
    end

    test "cross-school tag access is prevented", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)

      other_school = insert(:school)
      other_tag = insert(:student_insight_tag, school: other_school, name: "Other Tag")

      conn
      |> visit(@live_view_path <> "?tag_id=#{other_tag.id}")
      |> refute_has("#sparks-tag-form-overlay")
    end
  end

  describe "Permission-based access control" do
    test "users with school_management permission can see management UI", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("a[href*=\"?new=true\"]", text: "Add new tag")
    end

    test "users without school_management permission cannot see management UI", context do
      %{conn: conn, user: user} = set_user_permissions([], context)

      school_id = user.current_profile.school_id
      school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)
      tag = insert(:student_insight_tag, school: school, name: "Test Tag")

      conn
      |> visit(@live_view_path)
      |> refute_has("a[href*=\"?new=true\"]")
      |> refute_has("a[href*=\"?tag_id=#{tag.id}\"]", text: "Edit")
    end

    test "users without school_management permission cannot access tag form overlay", context do
      %{conn: conn, user: user} = set_user_permissions([], context)

      school_id = user.current_profile.school_id
      school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)
      tag = insert(:student_insight_tag, school: school, name: "Test Tag")

      conn
      |> visit(@live_view_path <> "?new=true")
      |> refute_has("#sparks-tag-form-overlay")

      conn
      |> visit(@live_view_path <> "?tag_id=#{tag.id}")
      |> refute_has("#sparks-tag-form-overlay")
    end
  end
end
