defmodule LantternWeb.StrandLive.LessonsComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Moment management" do
    test "create moment", %{conn: conn} do
      subject = insert(:subject, name: "Subject abc")
      strand = insert(:strand, subjects: [subject])

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("Create new moment")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> fill_in("Name", with: "Moment name abc")
        |> fill_in("Description", with: "Moment description abc")
        |> select("Subjects", option: "Subject abc")
        |> click_button("Save")
      end)
      |> assert_has("a", text: "Moment name abc")
    end

    test "edit moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("#moments-#{moment.id} button", "Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> fill_in("Name", with: "Moment zzz")
        |> click_button("Save")
      end)
      |> assert_has("a", text: "Moment zzz")
    end

    test "delete moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("#moments-#{moment.id} button", "Edit")
      |> click_button("#moment-form-overlay button", "Delete")
      |> refute_has("#moments-#{moment.id}")
    end
  end

  describe "Lesson tags" do
    test "create lesson with tags selected", %{conn: conn, staff_member: staff_member} do
      school = Lanttern.Repo.get!(Lanttern.Schools.School, staff_member.school_id)
      insert(:lesson_tag, school: school, name: "Important")
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("Create new lesson")
      |> within("#lesson-form-overlay", fn session ->
        session
        |> fill_in("Lesson name", with: "Tagged lesson")
        |> click_button("button", "Important")
        |> click_button("Save")
      end)
      # after creation, navigates to lesson detail page where tags are shown as badges
      |> assert_has("h1", text: "Tagged lesson")
      |> assert_has("span", text: "Important")
    end

    test "edit lesson to add tags", %{conn: conn, staff_member: staff_member} do
      school = Lanttern.Repo.get!(Lanttern.Schools.School, staff_member.school_id)
      insert(:lesson_tag, school: school, name: "Priority")
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand, name: "Lesson to tag")

      conn
      |> visit("/strands/lesson/#{lesson.id}")
      |> refute_has("span", text: "Priority")
      |> click_button("Edit")
      |> within("#lesson-form-overlay", fn session ->
        session
        |> click_button("button", "Priority")
        |> click_button("Save")
      end)
      |> assert_has("span", text: "Priority")
    end
  end

  describe "Lessons filtering" do
    test "list all lessons", %{conn: conn} do
      subject_a = insert(:subject, name: "Subject A")
      subject_b = insert(:subject, name: "Subject B")
      strand = insert(:strand, subjects: [subject_a, subject_b])
      moment = insert(:moment, strand: strand)

      insert(:lesson, strand: strand, moment: moment, subjects: [subject_a], name: "Lesson A")
      insert(:lesson, strand: strand, moment: moment, subjects: [subject_b], name: "Lesson B")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("h4", text: "Lesson A")
      |> assert_has("h4", text: "Lesson B")
    end

    test "list lessons filtered by subject", %{conn: conn} do
      subject_a = insert(:subject, name: "Subject A")
      subject_b = insert(:subject, name: "Subject B")
      strand = insert(:strand, subjects: [subject_a, subject_b])
      moment = insert(:moment, strand: strand)

      insert(:lesson, strand: strand, moment: moment, subjects: [subject_a], name: "Lesson A")
      insert(:lesson, strand: strand, moment: moment, subjects: [subject_b], name: "Lesson B")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_link("#lesson-filter-options a", "Subject A")
      |> assert_has("h4", text: "Lesson A")
      |> refute_has("h4", text: "Lesson B")
    end
  end
end
